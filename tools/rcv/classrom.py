"""Link every student's program into one ROM with a menu (the class ROM).

    python -m rcv.classrom [--programs DIR] [--demo] [-o build/classrom]

Programs are taken from packages/PNN-*/pNN.s (or DIR/pNN.s). A program that
is missing, still the starter, or does not assemble is replaced by a stub
that prints "PNN is not ready yet". The menu reads '#' and a package number,
runs that program, and stops at #0. This only works because every label starts
with pNN_ - the same idea as table prefixes in a shared database.
--demo runs the ROM on the simulator with every program's test1 input.
"""
import os
import sys
from pathlib import Path

from . import spec
from .asm import assemble
from .packages import PACKAGES
from .gen import folder, program_stub

ROOT = Path(os.environ.get("RCV_ROOT") or Path(__file__).resolve().parents[2])
LIB = ROOT / "sw" / "lib"


def monitor(ids):
    table = "\n".join(f"        .word   p{n:02d}_main" for n in range(1, 67))
    return f"""
        .text
main:
        addi    sp, sp, -8
        sw      ra, 4(sp)
        sw      s0, 0(sp)
        la      a0, rcv_mon_banner
        call    rcv_puts
rcv_mon_loop:
        la      a0, rcv_mon_prompt
        call    rcv_puts
rcv_mon_sync:                       # skip anything a program left unread, up to '#'
        call    rcv_getc
        li      t0, '#'
        bne     a0, t0, rcv_mon_sync
        call    rcv_read_dec
        mv      s0, a0
        beqz    s0, rcv_mon_quit
        li      t0, 66
        bgtu    s0, t0, rcv_mon_bad
        mv      a0, s0
        call    rcv_print_dec
        call    rcv_newline
        la      t0, rcv_mon_table
        slli    t1, s0, 2
        add     t0, t0, t1
        lw      t0, -4(t0)
        jalr    ra, 0(t0)
        j       rcv_mon_loop
rcv_mon_bad:
        la      a0, rcv_mon_badmsg
        call    rcv_puts
        j       rcv_mon_loop
rcv_mon_quit:
        la      a0, rcv_mon_bye
        call    rcv_puts
        lw      s0, 0(sp)
        lw      ra, 4(sp)
        addi    sp, sp, 8
        ret
        .rodata
rcv_mon_banner: .asciz "RC-V class ROM - built by 66 students. Type # and a package number (#1 to #66), #0 to stop.\\n"
rcv_mon_prompt: .asciz "\\nrc-v> "
rcv_mon_badmsg: .asciz "no such package\\n"
rcv_mon_bye:    .asciz "bye\\n"
        .align  2
rcv_mon_table:
{table}
"""


def stub(n):
    return f"""
        .text
p{n:02d}_main:
        addi    sp, sp, -4
        sw      ra, 0(sp)
        la      a0, p{n:02d}_nr
        call    rcv_puts
        lw      ra, 0(sp)
        addi    sp, sp, 4
        ret
p{n:02d}_nr: .asciz "P{n:02d} is not ready yet\\n"
        .align  2
"""


def collect(prog_dir=None):
    srcs, status = [], {}
    for p in PACKAGES:
        n = p["id"]
        path = Path(prog_dir) / f"p{n:02d}.s" if prog_dir else folder(p) / f"p{n:02d}.s"
        text = path.read_text(encoding="utf-8") if path.exists() else None
        ok = text is not None and text.strip() != program_stub(p).strip()
        if ok:
            trial = assemble([("crt0.s", (LIB / "crt0.s").read_text()), ("m.s", "main: ret\n"),
                              (path.name, text), ("lib.s", (LIB / "rcv_lib.s").read_text())])
            ok = not trial["errors"]
        body = text if ok else stub(n)
        # like a real linker: every program starts and ends on a word boundary in both
        # sections, whatever the previous program left behind (e.g. an odd-length string)
        align = "\n        .text\n        .align 2\n        .data\n        .align 2\n        .text\n"
        body = align + body + align
        srcs.append((path.name if ok else f"stub{n}.s", body))
        status[n] = "ready" if ok else "not ready"
    return srcs, status


def build(prog_dir=None):
    srcs, status = collect(prog_dir)
    res = assemble([("crt0.s", (LIB / "crt0.s").read_text()), ("monitor.s", monitor(status))] + srcs +
                   [("rcv_lib.s", (LIB / "rcv_lib.s").read_text())])
    return res, status


def demo_input(prog_dir=None, status=None):
    parts = []
    for p in PACKAGES:
        n = p["id"]
        t = folder(p) / "tests" / "program" / "test1.in"
        parts.append(f"#{n}\n" + (t.read_text() if t.exists() and status.get(n) == "ready" else ""))
    return "".join(parts) + "#0\n"


def main(argv=None):
    import argparse
    from .sim import run_result
    ap = argparse.ArgumentParser()
    ap.add_argument("--programs")
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("-o", "--out")
    a = ap.parse_args(argv)
    res, status = build(a.programs)
    if res["errors"]:
        print("\n".join(res["errors"][:30]))
        return 1
    ready = sum(1 for v in status.values() if v == "ready")
    print(f"class ROM: {ready}/66 programs, {(res['text_end']) // 4} words of code, "
          f"{res['data_end'] - spec.RAM_BASE} bytes of data", file=sys.stderr)
    if a.out:
        words = [res["rom"].get(4 * k, 0) for k in range(spec.ROM_WORDS)]
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text("".join(f"{w:08x}\n" for w in words))
    if a.demo:
        m = run_result(res, demo_input(a.programs, status), max_cycles=20_000_000)
        sys.stdout.write(m.output + m.screen_text())
        print(f"\n[{'halted' if m.dev['halt'].halted else 'cycle limit'} after {m.cycles} cycles]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
