# P29 program: RAM test.
        .text
p29_main:
        addi    sp, sp, -272
        sw      ra, 0(sp)

        jal     ra, rcv_read_dec
        mv      t0, a0

        addi    t1, sp, 8
        li      t2, 0
        li      t3, 64
p29_fill:
        sw      t2, 0(t1)
        add     t2, t2, t0
        addi    t1, t1, 4
        addi    t3, t3, -1
        bnez    t3, p29_fill

        addi    t1, sp, 8
        li      t2, 0
        li      t3, 64
        li      t4, 0
p29_check:
        lw      t5, 0(t1)
        bne     t5, t2, p29_error
        add     t4, t4, t5
        add     t2, t2, t0
        addi    t1, t1, 4
        addi    t3, t3, -1
        bnez    t3, p29_check

        sw      t4, 4(sp)
        la      a0, p29_ok
        jal     ra, rcv_puts
        la      a0, p29_sum
        jal     ra, rcv_puts
        lw      a0, 4(sp)
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline
        j       p29_done

p29_error:
        sw      t1, 4(sp)
        la      a0, p29_err
        jal     ra, rcv_puts
        lw      a0, 4(sp)
        jal     ra, rcv_print_hex
        jal     ra, rcv_newline

p29_done:
        lw      ra, 0(sp)
        addi    sp, sp, 272
        ret

        .rodata
p29_ok:
        .asciz  "RAM OK\n"
p29_sum:
        .asciz  "sum = "
p29_err:
        .asciz  "RAM error at "
        .align  2