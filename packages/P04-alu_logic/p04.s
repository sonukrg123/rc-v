# P04 program - bitwise calculator
        .text
p04_main:
        addi    sp, sp, -12
        sw      ra, 0(sp)
        sw      s0, 4(sp)
        sw      s1, 8(sp)

        call    rcv_read_hex
        mv      s0, a0              # s0 = A
        call    rcv_read_hex
        mv      s1, a0              # s1 = B

        la      a0, p04_l_and
        call    rcv_puts
        and     a0, s0, s1
        call    rcv_print_hex
        call    rcv_newline

        la      a0, p04_l_or
        call    rcv_puts
        or      a0, s0, s1
        call    rcv_print_hex
        call    rcv_newline

        la      a0, p04_l_xor
        call    rcv_puts
        xor     a0, s0, s1
        call    rcv_print_hex
        call    rcv_newline

        la      a0, p04_l_nota
        call    rcv_puts
        not     a0, s0
        call    rcv_print_hex
        call    rcv_newline

        la      a0, p04_l_nand
        call    rcv_puts
        and     a0, s0, s1
        not     a0, a0
        call    rcv_print_hex
        call    rcv_newline

        la      a0, p04_l_nor
        call    rcv_puts
        or      a0, s0, s1
        not     a0, a0
        call    rcv_print_hex
        call    rcv_newline

        lw      ra, 0(sp)
        lw      s0, 4(sp)
        lw      s1, 8(sp)
        addi    sp, sp, 12
        ret

        .rodata
p04_l_and:  .asciz "A AND B  = "
p04_l_or:   .asciz "A OR B   = "
p04_l_xor:  .asciz "A XOR B  = "
p04_l_nota: .asciz "NOT A    = "
p04_l_nand: .asciz "A NAND B = "
p04_l_nor:  .asciz "A NOR B  = "
        .align  2
