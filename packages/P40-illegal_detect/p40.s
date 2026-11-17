# P40 program - catch illegal instructions (see README.md).
# Reads N (1..5), installs its own trap handler, then runs a loop N times. Inside
# the loop, right after p40_bad, sit two illegal words. Each one traps (mcause 2);
# the handler reports it, counts it, skips the bad word (mepc + 4) and returns with mret.
#
# Registers kept by p40_main:  s0 = N,  s1 = loop counter,  s2 = trap count,
#                              s3 = the old mtvec (restored at the end).
# All s registers and sp are saved on entry and restored before ret.

        .text
p40_main:
        addi    sp, sp, -20
        sw      ra, 16(sp)
        sw      s0, 12(sp)
        sw      s1, 8(sp)
        sw      s2, 4(sp)
        sw      s3, 0(sp)

        call    rcv_read_dec            # a0 = N
        mv      s0, a0
        mv      s1, s0                  # loop counter = N
        li      s2, 0                   # trap count = 0

        csrr    s3, mtvec               # save the old handler address
        la      t0, p40_handler
        csrw    mtvec, t0               # install our own handler

p40_loop:
        beqz    s1, p40_done
p40_bad:
        .word   0x00000000              # illegal word 1 (offset 0)
        .word   0xFFFFFFFF              # illegal word 2 (offset 4)
        addi    s1, s1, -1
        j       p40_loop

p40_done:
        csrw    mtvec, s3               # restore the old handler

        la      a0, p40_msg_rec
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        la      a0, p40_msg_traps
        call    rcv_puts
        call    rcv_newline

        lw      s3, 0(sp)
        lw      s2, 4(sp)
        lw      s1, 8(sp)
        lw      s0, 12(sp)
        lw      ra, 16(sp)
        addi    sp, sp, 20
        ret

# ---- trap handler: print, count, skip the bad word, return with mret
p40_handler:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      a0, 8(sp)
        sw      t0, 4(sp)
        sw      t1, 0(sp)

        la      a0, p40_msg_ill
        call    rcv_puts
        csrr    a0, mcause
        call    rcv_print_hex           # 8 hex digits
        la      a0, p40_msg_off
        call    rcv_puts
        csrr    t0, mepc
        la      t1, p40_bad
        sub     a0, t0, t1              # offset = mepc - p40_bad
        call    rcv_print_dec
        call    rcv_newline

        addi    s2, s2, 1               # count the trap

        csrr    t0, mepc
        addi    t0, t0, 4               # skip the bad word
        csrw    mepc, t0

        lw      t1, 0(sp)
        lw      t0, 4(sp)
        lw      a0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        mret

        .rodata
p40_msg_ill:
        .asciz  "illegal instruction: mcause="
p40_msg_off:
        .asciz  " offset="
p40_msg_rec:
        .asciz  "recovered after "
p40_msg_traps:
        .asciz  " traps"
        .align  2