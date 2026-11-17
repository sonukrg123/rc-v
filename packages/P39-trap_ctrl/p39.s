# P39 program: software interrupt demo.
# Reads N (0..9), installs an interrupt handler, enables the software
# interrupt, raises it N times and prints "tick <count>" from the handler.
# Finally it switches interrupts off, restores mtvec and prints "done".
#
# Rules kept: p39_main is a subroutine that ends with ret, every label starts
# with p39_, and sp and s0-s11 have the same values when we return.

        .text
p39_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)              # save the return address
        sw      s0, 8(sp)               # s0 = how many interrupts are still to raise
        sw      s1, 4(sp)               # s1 = the old mtvec

        call    rcv_read_dec            # a0 = N
        mv      s0, a0

        la      t0, p39_count           # start counting from 0
        sw      zero, 0(t0)

        csrr    s1, mtvec               # remember the old trap vector
        la      t0, p39_isr
        csrw    mtvec, t0               # traps now jump to our handler

        li      t0, 0x10                # IRQ_MASK bit 4 = software interrupt
        li      t1, IRQ_MASK
        sw      t0, 0(t1)

        li      t0, 8                   # mstatus.MIE is bit 3
        csrs    mstatus, t0             # interrupts on

p39_loop:
        beqz    s0, p39_end             # all N interrupts raised?
        li      t1, IRQ_SWI
        li      t2, 1
        sw      t2, 0(t1)               # raise the software interrupt: the trap
                                        # is taken before the next instruction
        addi    s0, s0, -1              # runs after the handler has returned
        j       p39_loop

p39_end:
        li      t0, 8
        csrc    mstatus, t0             # interrupts off
        li      t1, IRQ_MASK
        sw      zero, 0(t1)             # mask every source again
        csrw    mtvec, s1               # put the old trap vector back

        la      a0, p39_done
        call    rcv_puts                # prints "done" and a newline

        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

# Interrupt handler. Hardware has already set mepc to the interrupted
# instruction and cleared MIE. The handler uses a0 and t0-t2 and calls library
# routines that may change ra, a0-a7 and t0-t6, so it saves all of them.
p39_isr:
        addi    sp, sp, -64
        sw      ra, 60(sp)
        sw      t0, 56(sp)
        sw      t1, 52(sp)
        sw      t2, 48(sp)
        sw      t3, 44(sp)
        sw      t4, 40(sp)
        sw      t5, 36(sp)
        sw      t6, 32(sp)
        sw      a0, 28(sp)
        sw      a1, 24(sp)
        sw      a2, 20(sp)
        sw      a3, 16(sp)
        sw      a4, 12(sp)
        sw      a5, 8(sp)
        sw      a6, 4(sp)
        sw      a7, 0(sp)

        li      t0, IRQ_SWI
        sw      zero, 0(t0)             # clear the request, or it fires again

        la      t0, p39_count
        lw      t1, 0(t0)
        addi    t1, t1, 1               # count = count + 1
        sw      t1, 0(t0)

        la      a0, p39_tick
        call    rcv_puts                # "tick "
        la      t0, p39_count
        lw      a0, 0(t0)
        call    rcv_print_dec           # the count
        call    rcv_newline

        lw      a7, 0(sp)
        lw      a6, 4(sp)
        lw      a5, 8(sp)
        lw      a4, 12(sp)
        lw      a3, 16(sp)
        lw      a2, 20(sp)
        lw      a1, 24(sp)
        lw      a0, 28(sp)
        lw      t6, 32(sp)
        lw      t5, 36(sp)
        lw      t4, 40(sp)
        lw      t3, 44(sp)
        lw      t2, 48(sp)
        lw      t1, 52(sp)
        lw      t0, 56(sp)
        lw      ra, 60(sp)
        addi    sp, sp, 64
        mret                            # back to the interrupted instruction,
                                        # MIE is restored by the hardware

        .data
p39_count:
        .word   0                       # how many ticks so far

        .rodata
p39_tick:
        .asciz  "tick "
p39_done:
        .asciz  "done\n"
        .align  2
