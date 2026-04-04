-- ============================================================================
--  Voice Magic — Hammerspoon Config
--  Hold ⌥D (Option+D) to record, release to transcribe + paste
-- ============================================================================

local VOICE_MAGIC_DIR = os.getenv("HOME") .. "/Documents/projects/voice-magic"
-- Actually a better way is to dynamically get the path of this script, but for now we fallback correctly
local file_info = debug.getinfo(1, "S")
local source_path = file_info.source:match("^@?(.*)/")
if source_path then
    VOICE_MAGIC_DIR = source_path
end

local AUDIO_FILE = "/tmp/voice_magic_recording.wav"
local PROCESS_SCRIPT = VOICE_MAGIC_DIR .. "/process.sh"
local SOX_PATH = "/opt/homebrew/bin/sox"

local recording = false
local soxTask = nil
local processingAlert = nil

hs.hotkey.bind({"alt"}, "d",
    function()
        if recording then return end
        recording = true
        hs.sound.getByFile("/System/Library/Sounds/Tink.aiff"):play()
        processingAlert = hs.alert.show("🎙️ Recording...", hs.alert.defaultStyle, hs.screen.mainScreen(), "forever")
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
            soxTask:terminate()
            hs.timer.usleep(300000)
        end
        hs.sound.getByFile("/System/Library/Sounds/Pop.aiff"):play()
        
        local activeModel = "AI"
        local skipLLM = false
        local file = io.open(VOICE_MAGIC_DIR .. "/voice-magic.conf", "r")
        if file then
            for line in file:lines() do
                local model = string.match(line, '^ACTIVE_MODEL="(.-)"')
                if model then activeModel = model end
                local skip = string.match(line, '^SKIP_LLM_PROCESSING="(.-)"')
                if skip == "true" then skipLLM = true end
            end
            file:close()
        end

        local alertText = skipLLM and "⚡ Transcribing..." or ("✨ Processing (" .. activeModel .. ")...")
        processingAlert = hs.alert.show(alertText, hs.alert.defaultStyle, hs.screen.mainScreen(), 30)
        
        local currentApp = "Unknown"
        local frontmost = hs.application.frontmostApplication()
        if frontmost then
            currentApp = frontmost:name()
        end

        hs.task.new("/bin/bash", function(exitCode)
            if processingAlert then hs.alert.closeSpecific(processingAlert) end
            if exitCode ~= 0 then hs.alert.show("⚠️ Voice Magic failed", 3) end
        end, {PROCESS_SCRIPT, currentApp, AUDIO_FILE}):start()
    end
)

local menubar = hs.menubar.new()
if menubar then
    menubar:setTitle("🎙️")
    menubar:setMenu({
        { title = "Voice Magic Active", disabled = true },
        { title = "-" },
        { title = "Hold ⌥D to dictate", disabled = true },
        { title = "-" },
        { title = "Open Folder", fn = function() hs.execute("open " .. VOICE_MAGIC_DIR) end },
        { title = "Reload", fn = function() hs.reload() end },
    })
end

hs.alert.show("🎙️ Voice Magic loaded — Hold ⌥D to dictate", 3)
