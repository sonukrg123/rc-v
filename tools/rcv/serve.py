"""RC-V console: run the class computer in your browser.

    python -m rcv.serve            (from tools/), then open http://localhost:8066

Pick a package, type its keyboard input and press Run. The page shows what the
RC-V computer printed on its terminal, its 4 x 16 text screen, its LEDs and hex
display, the registers, and how many clock cycles it took. Programs come from
packages/PNN-*/pNN.s, linked into one class ROM (the same ROM the class board
runs); "Reload" re-reads them after a git pull.
"""
import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from . import spec
from .classrom import build
from .gen import folder
from .packages import PACKAGES, BY_ID
from .sim import run_result

WEB = Path(__file__).with_name("web")
REGNAMES = ("zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 "
            "s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6").split()

_lock = threading.Lock()
_rom = {"res": None, "status": None}


def load_rom():
    with _lock:
        res, status = build()
        if res["errors"]:
            raise RuntimeError("; ".join(res["errors"][:5]))
        _rom["res"], _rom["status"] = res, status


def packages():
    out = []
    for p in PACKAGES:
        n = p["id"]
        t1 = folder(p) / "tests" / "program" / "test1.in"
        out.append({"id": n, "title": p["title"], "ready": _rom["status"].get(n) == "ready",
                    "example": t1.read_text() if t1.exists() else ""})
    return out


def run(n, text, max_cycles=5_000_000):
    """Run package n's program through the class ROM menu with `text` as keyboard input."""
    if n == -1:                      # the whole class demo: every program with its test1 input
        from .classrom import demo_input
        kbd, n = demo_input(None, _rom["status"]), 0
        max_cycles = 30_000_000
    else:
        kbd = (f"#{n}\n" + text + ("" if text.endswith("\n") or not text else "\n")) if n else ""
        kbd += "#0\n"
    m = run_result(_rom["res"], kbd, max_cycles=max_cycles)
    out = m.output
    # keep only this program's part of the terminal (after the menu echo of the number)
    marker = f"rc-v> {n}\n"
    body = out.split(marker, 1)[1] if n and marker in out else out
    body = body.rsplit("\nrc-v> ", 1)[0] if n else body
    d = m.dev
    return {
        "terminal": body,
        "full": out,
        "screen": d["screen"].dump(),
        "leds": d["gpio"].leds,
        "seg": d["gpio"].seg,
        "cycles": m.cycles,
        "instret": d["perf"].instret,
        "halted": bool(d["halt"].halted),
        "regs": {REGNAMES[k]: m.x[k] for k in range(32)},
        "pc": m.pc,
        "waiting": not d["halt"].halted,
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            return self.send(200, (WEB / "index.html").read_bytes(), "text/html; charset=utf-8")
        if self.path == "/api/packages":
            return self.send(200, json.dumps(packages()))
        return self.send(404, json.dumps({"error": "not found"}))

    def do_POST(self):
        try:
            n = int(self.headers.get("Content-Length") or 0)
            req = json.loads(self.rfile.read(n) or b"{}")
            if self.path == "/api/run":
                pkg = int(req.get("package", 0))
                if pkg not in BY_ID and pkg != -1:
                    return self.send(400, json.dumps({"error": "no such package"}))
                with _lock:
                    return self.send(200, json.dumps(run(pkg, str(req.get("input", ""))[:4000])))
            if self.path == "/api/reload":
                load_rom()
                return self.send(200, json.dumps({"ok": True, "ready": sum(1 for v in _rom["status"].values()
                                                                           if v == "ready")}))
        except Exception as e:        # show the problem in the page instead of crashing
            return self.send(500, json.dumps({"error": str(e)}))
        return self.send(404, json.dumps({"error": "not found"}))


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description="RC-V console in the browser")
    ap.add_argument("--port", type=int, default=8066)
    a = ap.parse_args(argv)
    load_rom()
    ready = sum(1 for v in _rom["status"].values() if v == "ready")
    print(f"RC-V console: {ready}/66 programs in the class ROM. Open http://localhost:{a.port}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", a.port), Handler).serve_forever()


if __name__ == "__main__":
    sys.exit(main())
