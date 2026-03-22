import http.server
import socketserver
import os

PORT = 5060
DIRECTORY = "/home/user/flutter_app/build/web"

class MapsCompatibleHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Google Maps用: iframeブロックを解除、オリジン許可
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        # X-Frame-Optionsは設定しない（iframeでの表示を許可）
        self.send_header('Content-Security-Policy',
            "frame-ancestors *; "
            "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:; "
            "script-src * 'unsafe-inline' 'unsafe-eval'; "
            "img-src * data: blob:; "
            "connect-src *; "
            "frame-src *;"
        )
        super().end_headers()

    def log_message(self, format, *args):
        pass  # ログを抑制

os.chdir(DIRECTORY)
with socketserver.TCPServer(('0.0.0.0', PORT), MapsCompatibleHandler) as httpd:
    httpd.allow_reuse_address = True
    print(f"Serving on port {PORT}")
    httpd.serve_forever()
