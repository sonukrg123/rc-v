# Print N x 1 through N x 10 using repeated addition.
        .text
p22_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)
        call    rcv_read_dec
        mv      s0, a0              # original N
        mv      s1, a0              # current product
        li      s2, 1               # multiplier/index
p22_loop:
        mv      a0, s0
        call    rcv_print_dec
        la      a0, p22_x
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        la      a0, p22_equals
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_dec
        call    rcv_newline
        add     s1, s1, s0
        addi    s2, s2, 1
        li      t0, 11
        blt     s2, t0, p22_loop
        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p22_x:      .asciz " x "
p22_equals: .asciz " = "
        .align 2
