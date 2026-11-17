"""Export the browser-only RC-V console (for GitHub Pages).

    python -m rcv.webexport ../site/console

Writes the class ROM (every student's program linked together), the package
list with example inputs, the simulator's Python files and the console page.
The page runs the simulator in the visitor's browser with Pyodide, so no
server is needed.
"""
import json
import shutil
import sys
from pathlib import Path

from . import spec
from .classrom import build
from .gen import folder
from .packages import PACKAGES

HERE = Path(__file__).resolve().parent


def export(out):
    out = Path(out)
    (out / "rcv").mkdir(parents=True, exist_ok=True)
    res, status = build()
    if res["errors"]:
        raise SystemExit("class ROM does not assemble: " + "; ".join(res["errors"][:5]))
    used = max(res["rom"]) // 4 + 1 if res["rom"] else 0
    rom = [res["rom"].get(4 * k, 0) for k in range(used)]
    pkgs = []
    for p in PACKAGES:
        t1 = folder(p) / "tests" / "program" / "test1.in"
        pkgs.append({"id": p["id"], "title": p["title"], "ready": status.get(p["id"]) == "ready",
                     "example": t1.read_text() if t1.exists() else ""})
    (out / "rom.json").write_text(json.dumps({"rom": rom, "packages": pkgs}), encoding="utf-8")
    for f in ("__init__.py", "spec.py", "devices.py", "sim.py"):
        src = HERE / f
        (out / "rcv" / f).write_text(src.read_text(encoding="utf-8") if src.exists() else "", encoding="utf-8")
    shutil.copy(HERE / "web" / "console_static.html", out / "index.html")
    ready = sum(1 for v in status.values() if v == "ready")
    print(f"console exported to {out}: {ready}/66 programs, ROM {used} words")


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else "site/console")
