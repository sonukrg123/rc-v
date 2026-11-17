# P55 program - see README.md for the task.
# Rules: start at the label p55_main and finish with ret; every label you
# create starts with p55_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

# P55 program: stack depth of a recursion
# Reads N, clears the stack guard, calls p55_sum(N), then prints the sum
# and how many bytes of stack the recursion used.
#
# Guard registers (slot 13, base 0x00020340, one 32-bit register every 4 bytes):
#   0x00020340 LIMIT   0x00020344 STATUS   0x00020348 MINSP

        .text
p55_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)          # save ra, s0, s1 (must give s0-s11 back unchanged)
        sw      s0, 8(sp)
        sw      s1, 4(sp)

        jal     ra, rcv_read_dec    # a0 = N
        mv      s0, a0              # s0 = N

        li      t0, 0x00020344      # SPGUARD_STATUS
        sw      zero, 0(t0)         # any write: clears STATUS, resets MINSP
        mv      s1, sp              # s1 = remembered sp

        mv      a0, s0
        jal     ra, p55_sum         # a0 = sum
        mv      s0, a0              # s0 = sum

        li      t0, 0x00020348      # SPGUARD_MINSP, read right after the call
        lw      t0, 0(t0)
        sub     s1, s1, t0          # s1 = remembered sp - MINSP

        la      a0, p55_msg_sum
        jal     ra, rcv_puts
        mv      a0, s0
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline

        la      a0, p55_msg_stack
        jal     ra, rcv_puts
        mv      a0, s1
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline

        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

# p55_sum(n) = n + p55_sum(n-1), p55_sum(0) = 0
# Every call, including n = 0, starts with addi sp, sp, -8.
p55_sum:
        addi    sp, sp, -8
        sw      ra, 4(sp)
        sw      a0, 0(sp)           # save n
        beqz    a0, p55_sum_base
        addi    a0, a0, -1
        jal     ra, p55_sum
        lw      t0, 0(sp)           # n
        add     a0, a0, t0          # n + sum(n-1)
        j       p55_sum_done
p55_sum_base:
        li      a0, 0
p55_sum_done:
        lw      ra, 4(sp)
        addi    sp, sp, 8
        ret

        .data
p55_msg_sum:
        .asciz  "sum = "
p55_msg_stack:
        .asciz  "stack bytes = "
