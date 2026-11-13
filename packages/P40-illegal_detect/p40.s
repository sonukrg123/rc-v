# P40 - Catch illegal instructions and resume execution.
# p40_main is a normal subroutine and preserves sp and s0-s11.
        .text
p40_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)
        call    rcv_read_dec
        mv      s0, a0
        li      s1, 0
        csrr    s2, mtvec
        la      t0, p40_trap
        csrw    mtvec, t0
        la      t0, p40_count
        sw      zero, 0(t0)
p40_loop:
p40_bad:
        .word   0x00000000
        .word   0xFFFFFFFF
        addi    s1, s1, 1
        blt     s1, s0, p40_loop
        csrw    mtvec, s2
        la      a0, p40_recovered
        call    rcv_puts
        la      t0, p40_count
        lw      a0, 0(t0)
        call    rcv_print_dec
        la      a0, p40_traps
        call    rcv_puts
        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

# Save all caller-saved registers used by the handler and its library calls.
p40_trap:
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
        la      t0, p40_count
        lw      t1, 0(t0)
        addi    t1, t1, 1
        sw      t1, 0(t0)
        la      a0, p40_illegal_text
        call    rcv_puts
        csrr    a0, mcause
        call    rcv_print_hex
        la      a0, p40_offset_text
        call    rcv_puts
        csrr    t0, mepc
        la      t1, p40_bad
        sub     a0, t0, t1
        call    rcv_print_dec
        call    rcv_newline
        csrr    t0, mepc
        addi    t0, t0, 4
        csrw    mepc, t0
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
        mret

        .rodata
p40_illegal_text:
        .asciz  "illegal instruction: mcause="
p40_offset_text:
        .asciz  " offset="
p40_recovered:
        .asciz  "recovered after "
p40_traps:
        .asciz  " traps\n"
        .align  2

        .data
p40_count:
        .word   0
