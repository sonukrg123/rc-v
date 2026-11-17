# P50 program: multiply two signed numbers with the MUL unit (I/O slot 8).
# Registers of the unit (base 0x00020200, one word each):
#   +0x00 MUL_A   +0x04 MUL_B   +0x08 MUL_CTRL (bit0 = start)
#   +0x0C MUL_STATUS (bit0 = busy)   +0x10 MUL_RESULT

        .text
p50_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)

        jal     ra, rcv_read_dec        # first number  -> a0
        mv      s0, a0
        jal     ra, rcv_read_dec        # second number -> a0
        mv      s1, a0

        lui     t0, 0x20                # t0 = 0x00020000
        addi    t0, t0, 0x200           # t0 = 0x00020200 (MUL base)
        sw      s0, 0(t0)               # MUL_A
        sw      s1, 4(t0)               # MUL_B
        li      t1, 1
        sw      t1, 8(t0)               # MUL_CTRL = 1 (start)

p50_wait:
        lw      t1, 12(t0)              # MUL_STATUS
        andi    t1, t1, 1               # busy bit
        bnez    t1, p50_wait            # poll while busy

        lw      s0, 16(t0)              # MUL_RESULT

        la      a0, p50_msg
        jal     ra, rcv_puts            # "product = "
        mv      a0, s0
        jal     ra, rcv_print_dec       # signed decimal
        jal     ra, rcv_newline

        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p50_msg:
        .asciz  "product = "
        .align  2
