# P27 program - see README.md for the task.
        .text
p27_main:
        addi    sp, sp, -32
        sw      ra, 16(sp)
        sw      s0, 20(sp)

        sw      zero, 0(sp)
        sw      zero, 4(sp)
        li      s0, 0

p27_read:
        jal     ra, rcv_getc
        li      t0, 10
        beq     a0, t0, p27_done
        bltz    a0, p27_done
        li      t0, 8
        bgeu    s0, t0, p27_read
        add     t1, sp, s0
        sb      a0, 0(t1)
        addi    s0, s0, 1
        j       p27_read

p27_done:
        la      a0, p27_msg0
        jal     ra, rcv_puts
        lw      a0, 0(sp)
        jal     ra, rcv_print_hex
        jal     ra, rcv_newline

        la      a0, p27_msg1
        jal     ra, rcv_puts
        lw      a0, 4(sp)
        jal     ra, rcv_print_hex
        jal     ra, rcv_newline

        lw      ra, 16(sp)
        lw      s0, 20(sp)
        addi    sp, sp, 32
        ret

        .rodata
p27_msg0:
        .asciz  "word 0 = "
p27_msg1:
        .asciz  "word 1 = "
        .align  2
