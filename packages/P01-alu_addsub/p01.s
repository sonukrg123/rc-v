# P01 program - see README.md for the task.
# Rules: start at the label p01_main and finish with ret; every label you
# create starts with p01_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).
#
# Reads signed decimals A and B, prints A+B and A-B, each with (overflow) or
# (no overflow), detected with the sign rule only.
#   s0 = A, s1 = B, s2 = A+B, s3 = A-B, s4 = sum overflow (0/1), s5 = diff overflow (0/1)

        .text
p01_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)
        sw      s5, 4(sp)

        # ---- read A and B ----
        jal     ra, rcv_read_dec
        mv      s0, a0                  # A
        jal     ra, rcv_read_dec
        mv      s1, a0                  # B

        # ---- results (wrap to 32 bits) ----
        add     s2, s0, s1              # A + B
        sub     s3, s0, s1              # A - B

        # ---- overflow of A+B: same sign in A and B, sum sign differs from A ----
        xor     t0, s0, s1
        xori    t0, t0, -1              # ~(A ^ B): sign bit 1 when A and B have equal signs
        xor     t1, s0, s2              # sign bit 1 when sum sign differs from A
        and     t0, t0, t1
        srli    s4, t0, 31

        # ---- overflow of A-B: A and B differ in sign, result sign differs from A ----
        xor     t0, s0, s1
        xor     t1, s0, s3
        and     t0, t0, t1
        srli    s5, t0, 31

        # ---- "A+B = <sum> (overflow|no overflow)" ----
        la      a0, p01_str_sum
        jal     ra, rcv_puts
        mv      a0, s2
        jal     ra, rcv_print_dec
        mv      a1, s4
        jal     ra, p01_print_flag

        # ---- "A-B = <diff> (overflow|no overflow)" ----
        la      a0, p01_str_diff
        jal     ra, rcv_puts
        mv      a0, s3
        jal     ra, rcv_print_dec
        mv      a1, s5
        jal     ra, p01_print_flag

        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        lw      s3, 12(sp)
        lw      s4, 8(sp)
        lw      s5, 4(sp)
        addi    sp, sp, 32
        ret

# p01_print_flag: a1 = 1 -> " (overflow)\n", a1 = 0 -> " (no overflow)\n"
p01_print_flag:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        beqz    a1, p01_pf_no
        la      a0, p01_str_ovf
        j       p01_pf_print
p01_pf_no:
        la      a0, p01_str_noovf
p01_pf_print:
        jal     ra, rcv_puts
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p01_str_sum:
        .asciz  "A+B = "
p01_str_diff:
        .asciz  "A-B = "
p01_str_ovf:
        .asciz  " (overflow)\n"
p01_str_noovf:
        .asciz  " (no overflow)\n"
        .align  2