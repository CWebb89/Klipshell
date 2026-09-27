#!/usr/bin/env python3
"""Transport test for MoonrakerService: boots the real QML service against a
stub Moonraker that reproduces its response envelope, drives it through the
public API, and asserts on the signals it emits.

This is the layer that had no test. A wrong success rule here reports every
successful command as a failure (and a wrong stash silently kills a feature),
and neither shows up in qmllint.

Usage: python3 tools/test-transport.py     (needs a Wayland session)
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TIMEOUT = 40


class Stub(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def _json(self, obj):
        body = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/printer/info"):
            return self._json({"result": {"state": "ready"}})
        if self.path.startswith("/server/history/list"):
            return self._json({"result": {"jobs": []}})
        if self.path.startswith("/printer/objects/query"):
            return self._json({"result": {"status": {}}})
        self._json({"result": {}})

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(n).decode("utf-8", "replace") if n else ""
        if "FAILME" in body:
            return self._json({"error": {"message": "klippy shutdown"}})
        self._json({"result": "ok"})


PROBE = r'''
import QtQuick
import Quickshell
import Quickshell.Io
import "./src/moonraker"
import "./src/views"

ShellRoot {
    id: shell

    property int step: 0
    property int waited: 0
    property int pass: 0
    property int fail: 0
    property var sent: ({ ok: null, err: "" })
    property var acted: ({ ok: null, msg: "" })

    MainWindow { id: mw }

    function check(name, got, want) {
        if (String(got) === String(want)) {
            shell.pass++
            console.error("KSAUDIT PASS " + name)
        } else {
            shell.fail++
            console.error("KSAUDIT FAIL " + name + " got=[" + got + "] want=[" + want + "]")
        }
    }

    Connections {
        target: MoonrakerService
        function onGcodeSent(ok, err) { shell.sent = { ok: ok, err: err } }
        function onActionDone(ok, status) { shell.acted = { ok: ok, msg: status } }
    }

    function phase1() {
        var P = MoonrakerService
        check("_postOk result-ok", JSON.stringify(P._postOk('{"result":"ok"}')), '{"ok":true,"err":""}')
        check("_postOk empty-fallback", JSON.stringify(P._postOk('{}')), '{"ok":true,"err":""}')
        check("_postOk blank", JSON.stringify(P._postOk('')), '{"ok":true,"err":""}')
        check("_postOk error envelope",
              JSON.stringify(P._postOk('{"error":{"message":"klippy shutdown"}}')),
              '{"ok":false,"err":"klippy shutdown"}')
        check("_postOk non-json", JSON.stringify(P._postOk("gateway timeout")),
              '{"ok":false,"err":"gateway timeout"}')
        check("_sq quote break-out", P._sq("a'b"), "a'\\''b")
        check("_encPath spaces", P._encPath("dir/my file.gcode"), "dir/my%20file.gcode")
        check("_encPath keeps slashes", P._encPath("config/sub/x.cfg"), "config/sub/x.cfg")
        try {
            P._seedDemo(null)
            check("_seedDemo(null) does not throw", "ok", "ok")
        } catch (e) {
            check("_seedDemo(null) does not throw", String(e), "ok")
        }
        P.data.history = { jobs: [ { filename: "x.gcode", status: "in_progress" },
                                   { filename: "x.gcode", status: "completed" } ] }
        check("fileStateOf newest job wins", P.fileStateOf("x.gcode"), "in_progress")
        check("fileStateOf unknown file", P.fileStateOf("nope.gcode"), "")
        P.sendGcode("M115")
    }

    function tick() {
        if (shell.step === 0) {
            shell.waited++
            if (MoonrakerService.activePrinter === "") {
                if (shell.waited > 100) shell.finish()
                return
            }
            shell.step = 1
            shell.phase1()
        } else if (shell.step === 1) {
            if (shell.sent.ok === null) return
            shell.check("sendGcode ok on {\"result\":\"ok\"}", shell.sent.ok, true)
            shell.check("sendGcode err empty", shell.sent.err, "")
            shell.step = 2
            shell.sent = { ok: null, err: "" }
            MoonrakerService.pausePrint()
        } else if (shell.step === 2) {
            if (shell.acted.ok === null) return
            shell.check("pausePrint ok", shell.acted.ok, true)
            shell.check("pausePrint status", shell.acted.msg, "paused")
            shell.step = 3
            shell.sent = { ok: null, err: "" }
            MoonrakerService.sendGcode("FAILME")
        } else if (shell.step === 3) {
            if (shell.sent.ok === null) return
            shell.check("failed command reports failure", shell.sent.ok, false)
            shell.check("failed command carries the message", shell.sent.err, "klippy shutdown")
            shell.step = 4
            shell.finish()
        }
    }

    function finish() {
        console.error("KSAUDIT DONE pass=" + shell.pass + " fail=" + shell.fail)
        Qt.quit()
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: shell.tick()
    }
}
'''


def build_tree(root, port):
    shutil.copytree(REPO / "src", root / "src")
    (root / "src" / "config" / "printers.json").write_text(
        json.dumps({"printers": [{"name": "STUB", "host": "127.0.0.1", "port": port}]})
    )
    (root / "shell.qml").write_text(PROBE)


def main():
    if not os.environ.get("WAYLAND_DISPLAY"):
        print("cannot run: no Wayland session (WAYLAND_DISPLAY unset)")
        return 2

    server = ThreadingHTTPServer(("127.0.0.1", 0), Stub)
    threading.Thread(target=server.serve_forever, daemon=True).start()

    root = Path(tempfile.mkdtemp(prefix="klipshell-transport-"))
    build_tree(root, server.server_address[1])
    try:
        proc = subprocess.run(
            ["quickshell", "-n", "-p", str(root)],
            capture_output=True, text=True, timeout=TIMEOUT,
        )
        log = proc.stdout + proc.stderr
    except subprocess.TimeoutExpired as e:
        log = (e.stdout or "") + (e.stderr or "")
        log = log if isinstance(log, str) else log.decode("utf-8", "replace")
        print("quickshell did not exit within %ds" % TIMEOUT)
    finally:
        server.shutdown()
        server.server_close()
        shutil.rmtree(root, ignore_errors=True)

    fails = [l for l in log.splitlines() if "KSAUDIT FAIL" in l]
    passes = [l for l in log.splitlines() if "KSAUDIT PASS" in l]
    for line in passes:
        print(line.split("KSAUDIT ", 1)[1])
    for line in fails:
        print(line.split("KSAUDIT ", 1)[1])

    scene = [l.strip() for l in log.splitlines()
             if "TypeError" in l or "Cannot assign to non-existent" in l
             or "Cannot read property" in l]
    for line in scene:
        print("scene error: " + line)

    done = any("KSAUDIT DONE" in l for l in log.splitlines())
    print("\n%d passed, %d failed" % (len(passes), len(fails)))
    if not done:
        print("INCOMPLETE — no DONE marker; quickshell output follows\n")
        print(log[-4000:])
        return 1
    return 1 if fails or scene else 0


if __name__ == "__main__":
    sys.exit(main())
