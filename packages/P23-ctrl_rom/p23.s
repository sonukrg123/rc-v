# P23 program - see README.md for the task.
# P23 program: GCD and LCM
        .text
p23_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        call    rcv_read_dec        # a0 = A
        mv      s0, a0              # s0 = A
        call    rcv_read_dec        # a0 = B
        mv      s1, a0              # s1 = B
        beq     s0, zero, p23_zero
        beq     s1, zero, p23_zero

        mv      t0, s0              # t0 = working copy of A
        mv      t1, s1              # t1 = working copy of B

p23_loop:
        beq     t0, t1, p23_done    # a == b -> finished
        bltu    t0, t1, p23_b_bigger
        sub     t0, t0, t1          # a > b : a = a - b
        j       p23_loop
p23_b_bigger:
        sub     t1, t1, t0          # b > a : b = b - a
        j       p23_loop

p23_done:
        mv      s2, t0              # s2 = GCD

        la      a0, p23_str_gcd
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_udec
        call    rcv_newline

        mv      a0, s0              # a0 = A
        mv      a1, s2              # a1 = GCD
        # divide first: (A/GCD)*B avoids overflowing 32 bits like A*B would
        call    rcv_udiv            # a0 = A / GCD
        mv      a1, s1              # a1 = B
        call    rcv_umul            # a0 = (A / GCD) * B
        mv      s0, a0              # s0 = LCM
        
p23_print_lcm:
        la      a0, p23_str_lcm
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_udec
        call    rcv_newline

        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret 
        p23_zero:
        add     s2, s0, s1          # gcd(0, x) = x
        la      a0, p23_str_gcd
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_udec
        call    rcv_newline
        li      s0, 0               # lcm(0, x) = 0
        j       p23_print_lcm

        .rodata
p23_str_gcd:
        .asciz  "gcd = "
p23_str_lcm:
        .asciz  "lcm = "
        .align  2
