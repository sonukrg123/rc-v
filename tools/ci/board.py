"""Build the public class board (GitHub Pages) from check results.

    python tools/ci/board.py check.json members.json classrom.txt out_dir

check.json  : output of `python -m rcv.check 1 2 ... 66 --json`
members.json: the registry (package -> GitHub account)
classrom.txt: output of the class ROM demo (may be missing)
"""
import datetime
import html
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rcv.packages import PACKAGES, GROUPS  # noqa: E402

REPO = "https://github.com/campus-sutra/rc-v"
PARTS = ["digital", "verilog", "program", "dossier"]
LABEL = {"digital": "D", "verilog": "V", "program": "S", "dossier": "R"}


def main(check_path, members_path, rom_path, out):
    check = json.loads(Path(check_path).read_text()) if Path(check_path).exists() else {}
    members = json.loads(Path(members_path).read_text()) if Path(members_path).exists() else {}
    rom = Path(rom_path).read_text(errors="replace") if Path(rom_path).exists() else ""
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    totals = {k: 0 for k in PARTS}
    joined = 0
    tiles = []
    status = {}
    for g, gname in GROUPS.items():
        cells = []
        for p in [q for q in PACKAGES if q["group"] == g]:
            n = p["id"]
            r = check.get(str(n), {})
            m = members.get(str(n))
            joined += bool(m)
            st = {k: r.get(k, {}).get("status", "not started") for k in PARTS}
            for k in PARTS:
                totals[k] += st[k] == "pass"
            status[n] = {"github": m["github"] if m else None, **st}
            done = sum(st[k] == "pass" for k in PARTS)
            cls = "done" if done == 4 else ("work" if m else "open")
            parts = "".join(f'<span class="pt {st[k].replace(" ", "")}" title="{k}: {st[k]}">{LABEL[k]}</span>'
                            for k in PARTS)
            who = f'@{html.escape(m["github"])}' if m else "not joined"
            cells.append(f'<a class="tile {cls}" href="{REPO}/tree/main/packages/P{n:02d}-{p["slug"]}">'
                         f'<b>P{n:02d}</b><span class="t">{html.escape(p["title"])}</span>'
                         f'<span class="w">{who}</span><span class="pts">{parts}</span></a>')
        tiles.append(f'<h2>{g}. {html.escape(gname)}</h2><div class="grid">{"".join(cells)}</div>')
    hw_ready = totals["verilog"]
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    rom_block = (f"<pre>{html.escape(rom[-6000:])}</pre>" if rom else
                 "<p>The class ROM runs here once programs are merged.</p>")
    (out / "status.json").write_text(json.dumps({"updated": now, "joined": joined, "totals": totals,
                                                 "packages": status}, indent=1))
    (out / "index.html").write_text(f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>RC-V class board</title>
<style>
:root{{--bg:#f7f7f5;--fg:#1d1d1b;--mut:#6b6b66;--card:#fff;--line:#ddd;--ok:#2e7d32;--bad:#c62828;--open:#9e9e9e;--work:#ef8f00}}
@media (prefers-color-scheme:dark){{:root{{--bg:#151515;--fg:#eee;--mut:#9a9a94;--card:#1f1f1f;--line:#333}}}}
body{{margin:0;padding:16px;background:var(--bg);color:var(--fg);font:15px/1.4 system-ui,Segoe UI,sans-serif}}
main{{max-width:1100px;margin:auto}} h1{{margin:.2em 0}} h2{{font-size:1rem;margin:1.4em 0 .5em;color:var(--mut)}}
.kpis{{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:8px;margin:12px 0}}
.kpi{{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:10px}} .kpi b{{font-size:1.6rem;display:block}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:8px}}
.tile{{display:flex;flex-direction:column;gap:2px;background:var(--card);border:1px solid var(--line);border-left:5px solid var(--open);
border-radius:8px;padding:8px;color:inherit;text-decoration:none}} .tile.work{{border-left-color:var(--work)}} .tile.done{{border-left-color:var(--ok)}}
.t{{font-size:.85rem}} .w{{font-size:.8rem;color:var(--mut)}} .pts{{display:flex;gap:3px;margin-top:4px}}
.pt{{width:20px;height:20px;border-radius:4px;font-size:.7rem;display:grid;place-items:center;background:var(--line);color:var(--mut)}}
.pt.pass{{background:var(--ok);color:#fff}} .pt.fail{{background:var(--bad);color:#fff}}
pre{{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:10px;overflow:auto;max-height:420px;font-size:12px}}
</style></head><body><main>
<h1>RC-V class board</h1>
<p>66 students, one computer. Each tile is one package: D = Digital circuit, V = Verilog, S = RISC-V program,
R = dossier (green = passes, red = fails, grey = not handed in). Updated {now}.</p>
<div class="kpis">
<div class="kpi"><b>{joined}/66</b>joined</div>
<div class="kpi"><b>{totals['digital']}/66</b>Digital circuits pass</div>
<div class="kpi"><b>{hw_ready}/66</b>Verilog modules pass</div>
<div class="kpi"><b>{totals['program']}/66</b>programs pass</div>
<div class="kpi"><b>{totals['dossier']}/66</b>dossiers done</div>
</div>
{''.join(tiles)}
<h2>Run the class computer</h2>
<p><a href="console/"><b>Open the RC-V console</b></a>: pick any student's package, type its input and run it in your
browser. It shows the terminal, the text screen, the LEDs and the hex display.</p>
<h2>The class ROM on the RC-V simulator</h2>
<p>Every merged program linked into one ROM with a menu, run with each program's first test input.</p>
{rom_block}
<p><a href="{REPO}">Repository</a> · <a href="{REPO}/blob/main/docs/GETTING-STARTED.md">Getting started</a></p>
</main></body></html>
""", encoding="utf-8")


if __name__ == "__main__":
    main(*sys.argv[1:5])
