#!/usr/bin/env python3
"""Verify GitHub push webhooks and run the existing deployment script."""
import hashlib
import hmac
import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

SECRET = os.environ.get("WEBHOOK_SECRET", "").encode()
if not SECRET:
    raise RuntimeError("WEBHOOK_SECRET must be set")


class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)
        signature = self.headers.get("X-Hub-Signature-256", "")
        expected = "sha256=" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(signature, expected):
            self.send_error(401, "invalid webhook signature")
            return
        payload = json.loads(body)
        if self.headers.get("X-GitHub-Event") != "push" or payload.get("ref") != "refs/heads/main":
            self.send_response(202); self.end_headers(); self.wfile.write(b"event ignored")
            return
        subprocess.Popen(["/opt/rohithaws/deploy.sh"], start_new_session=True)
        self.send_response(202); self.end_headers(); self.wfile.write(b"deployment started")


HTTPServer(("127.0.0.1", int(os.environ.get("PORT", "9000"))), WebhookHandler).serve_forever()
