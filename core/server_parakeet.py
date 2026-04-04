#!/usr/bin/env python3
import sys, warnings, os
from http.server import HTTPServer, BaseHTTPRequestHandler
warnings.filterwarnings('ignore')

try:
    from parakeet_mlx import from_pretrained
    model = from_pretrained('mlx-community/parakeet-tdt-0.6b-v3')
except Exception as e:
    print(f"Error loading model: {e}")
    sys.exit(1)

class ParakeetHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8').strip()
        
        print(f"[DEBUG] Received Audio Stream: {post_data}", flush=True)
        
        try:
            if not os.path.exists(post_data):
                raise Exception(f"File not found: {post_data}")
                
            res = model.transcribe(post_data)
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            
            # Send raw text back
            print(f"[DEBUG] Transcription payload dispatched: {res.text[:50]}...", flush=True)
            self.wfile.write(res.text.encode('utf-8'))
        except Exception as e:
            print(f"[ERROR] Inference failed: {str(e)}", flush=True)
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode('utf-8'))

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8082
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, ParakeetHandler)
    print(f"Parakeet server running on port {port}...")
    httpd.serve_forever()
