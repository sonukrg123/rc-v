# P58 program - branch prediction of a loop (I/O slot 16, base 0x00020400)
# Reads N, runs the same counting loop twice, prints the 2nd run's counters.

        .equ    p58_BASE,     0x00020400
        .equ    p58_BRANCHES, 0          # ASSUMED: register 0 -> offset 0
        .equ    p58_CORRECT,  4          # ASSUMED: register 1 -> offset 4
        .equ    p58_CLEAR,    8          # ASSUMED: register 2 -> offset 8

        .text
p58_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)

        call    rcv_read_dec            # a0 = N
        mv      s0, a0                  # s0 = N
        li      s1, 2                   # two runs of the same loop code
        li      s2, p58_BASE

p58_run:
        sw      zero, p58_CLEAR(s2)     # clear the counters
        mv      t0, s0
p58_loop:
        addi    t0, t0, -1
        bnez    t0, p58_loop            # the only branch inside the run
        lw      s3, p58_BRANCHES(s2)    # read before any other branch executes
        lw      s4, p58_CORRECT(s2)
        addi    s1, s1, -1
        bnez    s1, p58_run             # outer-loop branch, after the reads

        la      a0, p58_s_br
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_dec
        call    rcv_newline
        la      a0, p58_s_ok
        call    rcv_puts
        mv      a0, s4
        call    rcv_print_dec
        call    rcv_newline

        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        lw      s3, 12(sp)
        lw      s4, 8(sp)
        addi    sp, sp, 32
        ret

        .rodata
p58_s_br:
        .asciz  "branches: "
p58_s_ok:
        .asciz  "correct: "
        .align  2
