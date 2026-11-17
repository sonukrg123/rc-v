# P47 program: Timer interrupt ticks
# Reads N, installs an interrupt handler, prints "tick k" for N timer ticks, then "done".
# Registers kept across the call: s0 = N, s1 = saved mtvec, s2 = ticks printed so far

        .text
p47_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        call    rcv_read_dec            # a0 = N
        mv      s0, a0

        csrr    s1, mtvec               # save old trap vector
        la      t0, p47_isr
        csrw    mtvec, t0               # install our handler

        la      t0, p47_ticks           # tick counter = 0
        sw      zero, 0(t0)

        li      t0, TIMER_COUNT         # count = 0
        sw      zero, 0(t0)
        li      t0, TIMER_CMP           # compare = 300
        li      t1, 300
        sw      t1, 0(t0)
        li      t0, IRQ_MASK            # enable source 0 (timer)
        li      t1, 1
        sw      t1, 0(t0)
        li      t0, TIMER_CTRL          # enable + interrupt enable
        li      t1, 3
        sw      t1, 0(t0)

        li      t0, 8                   # mstatus.MIE = 1
        csrs    mstatus, t0

        li      s2, 0                   # ticks printed
p47_loop:
        bge     s2, s0, p47_finish      # printed N lines?
p47_wait:
        la      t0, p47_ticks
        lw      t1, 0(t0)
        beq     t1, s2, p47_wait        # wait until the counter changes
        addi    s2, s2, 1
        la      a0, p47_tick_msg
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        call    rcv_newline
        j       p47_loop

p47_finish:
        li      t0, 8                   # mstatus.MIE = 0
        csrc    mstatus, t0
        li      t0, TIMER_CTRL          # stop the timer
        sw      zero, 0(t0)
        li      t0, IRQ_MASK            # clear the mask
        sw      zero, 0(t0)
        csrw    mtvec, s1               # restore old trap vector
        la      a0, p47_done_msg
        call    rcv_puts

        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

# ---- interrupt handler: saves every register it uses ----
p47_isr:
        addi    sp, sp, -8
        sw      t0, 4(sp)
        sw      t1, 0(sp)

        li      t0, TIMER_COUNT         # restart the count
        sw      zero, 0(t0)
        li      t0, TIMER_STATUS        # clear the match flag
        li      t1, 1
        sw      t1, 0(t0)

        la      t0, p47_ticks           # ticks = ticks + 1
        lw      t1, 0(t0)
        addi    t1, t1, 1
        sw      t1, 0(t0)

        lw      t1, 0(sp)
        lw      t0, 4(sp)
        addi    sp, sp, 8
        mret

        .rodata
p47_tick_msg:
        .asciz  "tick "
p47_done_msg:
        .asciz  "done\n"
        .align  2

        .data
p47_ticks:
        .word   0
