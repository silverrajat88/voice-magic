-- ============================================================================
--  Voice Magic — Hammerspoon Config
--  Hold ⌥D (Option+D) to record, release to transcribe + paste
-- ============================================================================

local file_info = debug.getinfo(1, "S")
local VOICE_MAGIC_DIR = file_info.source:match("^@?(.*)/")
if not VOICE_MAGIC_DIR then
    error("Could not determine Voice Magic directory")
end

local AUDIO_FILE = "/tmp/voice_magic_recording.wav"
local PROCESS_SCRIPT = VOICE_MAGIC_DIR .. "/process.sh"

-- Dynamic Homebrew Path Resolution (Intel vs Apple Silicon)
local function getSoxPath()
    local f1 = io.open("/opt/homebrew/bin/sox", "r")
    if f1 then f1:close(); return "/opt/homebrew/bin/sox" end
    local f2 = io.open("/usr/local/bin/sox", "r")
    if f2 then f2:close(); return "/usr/local/bin/sox" end
    return "sox"
end
local SOX_PATH = getSoxPath()

local elegantStyle = {
    strokeColor = {white = 1, alpha = 0.1},
    fillColor = {white = 0.05, alpha = 0.85},
    textColor = {white = 1, alpha = 1},
    strokeWidth = 1,
    radius = 16,
    textSize = 24,
    fadeInDuration = 0.15,
    fadeOutDuration = 0.25,
    textFont = ".AppleSystemUIFont",
    padding = 24
}

-- ── LOAD GLOBAL CONFIG ──────────────────────────────────────────────────────
local activeModel = "llama3"
local sttEngine = "whisper"
local skipLLM = false
local autoStartServers = true

local conf_file = io.open(VOICE_MAGIC_DIR .. "/voice-magic.conf", "r")
if conf_file then
    for line in conf_file:lines() do
        local model = string.match(line, '^%s*ACTIVE_MODEL%s*=%s*"(.-)"')
        if model then activeModel = model end
        local stt = string.match(line, '^%s*STT_ENGINE%s*=%s*"(.-)"')
        if stt then sttEngine = stt end
        local skip = string.match(line, '^%s*SKIP_LLM_PROCESSING%s*=%s*"(.-)"')
        if skip == "true" then skipLLM = true end
        local autoStart = string.match(line, '^%s*AUTO_START_SERVERS%s*=%s*"(.-)"')
        if autoStart == "false" then autoStartServers = false end
    end
    conf_file:close()
end

local function updateConfig(key, value)
    local confPath = VOICE_MAGIC_DIR .. "/voice-magic.conf"
    local file = io.open(confPath, "r")
    if not file then return end
    local content = file:read("*a")
    file:close()
    
    -- Universal regex: Find ^VARIABLE="value" and replace with VARIABLE="new_value"
    -- Handles leading spaces, different quotes, and ensures it matches even on first line
    local pattern = "(%c%s*)" .. key .. "=%b\"\""
    local replacement = "%1" .. key .. "=\"" .. value .. "\""
    local newContent, count = string.gsub(content, pattern, replacement)
    
    -- Fallback for first line (where no leading newline exists)
    if count == 0 then
        pattern = "^%s*" .. key .. "=%b\"\""
        replacement = key .. "=\"" .. value .. "\""
        newContent, count = string.gsub(content, pattern, replacement)
    end
    
    local wfile = io.open(confPath, "w")
    wfile:write(newContent)
    wfile:close()
    
    -- Tiny delay to ensure OS flushes the file buffer before calling reload
    hs.timer.doAfter(0.1, function() hs.reload() end)
end
-- ─────────────────────────────────────────────────────────────────────────────

local recording = false
local soxTask = nil
local processingAlert = nil

hs.hotkey.bind({"alt"}, "d",
    function()
        if recording then return end
        recording = true
        hs.sound.getByFile("/System/Library/Sounds/Tink.aiff"):play()
        processingAlert = hs.alert.show("🎙️ Recording...", elegantStyle, hs.screen.mainScreen(), "forever")
        soxTask = hs.task.new(SOX_PATH, nil, {
            "-d", "-r", "16000", "-c", "1", "-b", "16", AUDIO_FILE
        })
        soxTask:start()
    end,
    function()
        if not recording then return end
        recording = false
        if processingAlert then hs.alert.closeSpecific(processingAlert) end
        if soxTask and soxTask:isRunning() then
            local maxWait = 10
            while soxTask:isRunning() and maxWait > 0 do
                hs.timer.usleep(100000)
                maxWait = maxWait - 1
            end
            if soxTask:isRunning() then
                soxTask:terminate()
                hs.timer.usleep(500000)
            end
        end
        hs.sound.getByFile("/System/Library/Sounds/Pop.aiff"):play()

        local alertText
        if skipLLM then
            alertText = "⚡ Transcribing (" .. sttEngine .. ")..."
        else
            alertText = "✨ Processing (" .. sttEngine .. " → " .. activeModel .. ")..."
        end
        processingAlert = hs.alert.show(alertText, elegantStyle, hs.screen.mainScreen(), 30)
        
        hs.task.new("/bin/bash", function(exitCode)
            if processingAlert then hs.alert.closeSpecific(processingAlert) end
            if exitCode ~= 0 then hs.alert.show("⚠️ Voice Magic failed", elegantStyle, hs.screen.mainScreen(), 3) end
        end, {PROCESS_SCRIPT, AUDIO_FILE}):start()
    end
)

local menubar = hs.menubar.new()
if menubar then
    menubar:setTitle("🎙️")
    menubar:setMenu({
        { title = "Voice Magic Active", disabled = true },
        { title = "-" },
        { title = "🟢 Start Memory Servers (Fast)", fn = function() 
            hs.alert.show("🟢 Booting Servers...", elegantStyle, hs.screen.mainScreen(), 3)
            hs.task.new("/bin/bash", nil, {VOICE_MAGIC_DIR .. "/core/start_servers.sh"}):start()
        end },
        { title = "🔴 Kill Memory Servers (Save RAM)", fn = function() 
            hs.task.new("/bin/bash", nil, {VOICE_MAGIC_DIR .. "/core/stop_servers.sh"}):start()
            hs.alert.show("🔴 Servers Terminated", elegantStyle, hs.screen.mainScreen(), 2)
        end },
        { title = "-" },
        { title = "⚙️ Settings", menu = {
            { title = "STT Engine", menu = {
                { title = "Parakeet (Fastest)", checked = (sttEngine == "parakeet"), fn = function() updateConfig("STT_ENGINE", "parakeet") end },
                { title = "Whisper (Translate)", checked = (sttEngine == "whisper"), fn = function() updateConfig("STT_ENGINE", "whisper") end }
            }},
            { title = "Refinement Model", menu = {
                { title = "Llama 3 (General)", checked = (activeModel == "llama3"), fn = function() updateConfig("ACTIVE_MODEL", "llama3") end },
                { title = "DeepSeek (Coder)", checked = (activeModel == "deepseek"), fn = function() updateConfig("ACTIVE_MODEL", "deepseek") end },
                { title = "Qwen 2.5 (Coder)", checked = (activeModel == "qwencoder"), fn = function() updateConfig("ACTIVE_MODEL", "qwencoder") end }
            }},
            { title = "Bypass AI Grammar", menu = {
                { title = "Off (Use AI Refinement)", checked = not skipLLM, fn = function() updateConfig("SKIP_LLM_PROCESSING", "false") end },
                { title = "On (Paste Raw Audio)", checked = skipLLM, fn = function() updateConfig("SKIP_LLM_PROCESSING", "true") end }
            }},
            { title = "Auto-Start Servers", menu = {
                { title = "Enabled", checked = autoStartServers, fn = function() updateConfig("AUTO_START_SERVERS", "true") end },
                { title = "Disabled", checked = not autoStartServers, fn = function() updateConfig("AUTO_START_SERVERS", "false") end }
            }}
        }},
        { title = "-" },
        { title = "Open Folder", fn = function() hs.execute("open " .. VOICE_MAGIC_DIR) end },
        { title = "Reload Config", fn = function() hs.reload() end },
    })
end

if autoStartServers then
    hs.task.new("/bin/bash", nil, {VOICE_MAGIC_DIR .. "/core/start_servers.sh"}):start()
end

hs.alert.show("🎙️ Voice Magic loaded — Hold ⌥D to dictate", elegantStyle, hs.screen.mainScreen(), 3)
