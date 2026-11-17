# P13 program - count character kinds
# Reads one line, prints vowels, consonants, digits and spaces.
# s0 = pointer, s1 = vowels, s2 = consonants, s3 = digits, s4 = spaces

        .text
p13_main:
        addi    sp, sp, -128
        sw      ra, 124(sp)
        sw      s0, 120(sp)
        sw      s1, 116(sp)
        sw      s2, 112(sp)
        sw      s3, 108(sp)
        sw      s4, 104(sp)

        mv      a0, sp              # line buffer at 0(sp), 96 bytes
        li      a1, 96
        call    rcv_read_line

        mv      s0, sp
        li      s1, 0
        li      s2, 0
        li      s3, 0
        li      s4, 0

p13_loop:
        lbu     t0, 0(s0)
        beqz    t0, p13_done
        addi    s0, s0, 1

        li      t1, 32
        beq     t0, t1, p13_space

        addi    t1, t0, -48
        li      t2, 10
        bltu    t1, t2, p13_digit

        ori     t1, t0, 0x20        # make lower case
        addi    t1, t1, -97         # 'a' -> 0
        li      t2, 26
        bgeu    t1, t2, p13_loop    # not a letter: ignore

        beqz    t1, p13_vowel       # a
        li      t2, 4
        beq     t1, t2, p13_vowel   # e
        li      t2, 8
        beq     t1, t2, p13_vowel   # i
        li      t2, 14
        beq     t1, t2, p13_vowel   # o
        li      t2, 20
        beq     t1, t2, p13_vowel   # u

        addi    s2, s2, 1           # consonant
        j       p13_loop

p13_vowel:
        addi    s1, s1, 1
        j       p13_loop

p13_digit:
        addi    s3, s3, 1
        j       p13_loop

p13_space:
        addi    s4, s4, 1
        j       p13_loop

p13_done:
        la      a0, p13_msg_v
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_udec
        call    rcv_newline

        la      a0, p13_msg_c
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_udec
        call    rcv_newline

        la      a0, p13_msg_d
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_udec
        call    rcv_newline

        la      a0, p13_msg_s
        call    rcv_puts
        mv      a0, s4
        call    rcv_print_udec
        call    rcv_newline

        lw      s4, 104(sp)
        lw      s3, 108(sp)
        lw      s2, 112(sp)
        lw      s1, 116(sp)
        lw      s0, 120(sp)
        lw      ra, 124(sp)
        addi    sp, sp, 128
        ret

        .rodata
p13_msg_v:
        .asciz  "vowels: "
p13_msg_c:
        .asciz  "consonants: "
p13_msg_d:
        .asciz  "digits: "
p13_msg_s:
        .asciz  "spaces: "
        .align  2
