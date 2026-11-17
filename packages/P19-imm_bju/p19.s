# P19 program - Multiples of 7
# Reads N, prints every multiple of 7 from 7 up to N (by repeated addition),
# then the count.
#
#   multiples: 7 14 21 28
#   count: 4
#
# Registers (callee-saved, so the library calls cannot clobber them):
#   s0 = N, s1 = current multiple, s2 = count

        .text
p19_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        call    rcv_read_dec            # N -> a0
        mv      s0, a0
        li      s1, 7                   # first multiple
        li      s2, 0                   # count

        la      a0, p19_msg_mult
        call    rcv_puts

p19_loop:
        bgt     s1, s0, p19_done        # multiple > N (also handles N < 7)
        li      a0, 32                  # one space in front of each number
        call    rcv_putc
        mv      a0, s1
        call    rcv_print_dec
        addi    s2, s2, 1
        addi    s1, s1, 7               # next multiple by adding 7
        j       p19_loop

p19_done:
        call    rcv_newline
        la      a0, p19_msg_count
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        call    rcv_newline

        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p19_msg_mult:
        .asciz  "multiples:"
p19_msg_count:
        .asciz  "count: "
        .align  2