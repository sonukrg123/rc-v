# P45 - decimal input to packed BCD and an eight-position display scan.
# No multiply/divide extension is needed: rcv_udiv supplies division.

        .text
p45_main:
        # Keep the caller's return address and every saved register we use.
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)

        call    rcv_read_dec
        mv      s0, a0              # remaining decimal number
        li      s1, 0               # packed BCD accumulator
        li      s2, 0               # nibble shift: 0, 4, ..., 28
        li      s3, 8

p45_convert:
        mv      a0, s0
        li      a1, 10
        call    rcv_udiv            # a0 = quotient, a1 = decimal digit
        mv      s0, a0
        sll     t0, a1, s2
        or      s1, s1, t0
        addi    s2, s2, 4
        addi    s3, s3, -1
        bnez    s3, p45_convert

        li      t0, GPIO_SEG
        sw      s1, 0(t0)
        lw      s1, 0(t0)           # report the register's actual readback
        la      a0, p45_seg_text
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_hex
        call    rcv_newline

        li      s2, 0               # scan position k
p45_scan:
        addi    a0, s2, 48
        call    rcv_putc
        la      a0, p45_anode_text
        call    rcv_puts

        li      t0, 1
        sll     s3, t0, s2          # one-hot anode = 1 << k
        li      s4, 7               # print MSB first, retaining leading zeros
p45_anode_bits:
        srl     t0, s3, s4
        andi    a0, t0, 1
        addi    a0, a0, 48
        call    rcv_putc
        addi    s4, s4, -1
        bgez    s4, p45_anode_bits

        la      a0, p45_digit_text
        call    rcv_puts
        slli    t0, s2, 2           # nibble k begins at bit 4*k
        srl     t1, s1, t0
        andi    a0, t1, 15
        addi    a0, a0, 48          # valid packed BCD has digits 0 through 9
        call    rcv_putc
        call    rcv_newline

        addi    s2, s2, 1
        li      t0, 8
        blt     s2, t0, p45_scan

        lw      s4, 8(sp)
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret

        .rodata
p45_seg_text:
        .asciz  "SEG = "
p45_anode_text:
        .asciz  ": anode="
p45_digit_text:
        .asciz  " digit="
        .align  2
