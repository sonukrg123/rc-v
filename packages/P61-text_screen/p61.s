# P61 program: word wrap on the text screen
# Rules: start at the label p61_main and finish with ret; every label starts
# with p61_ ; sp and s0-s11 are kept.
#
# Registers used (all saved on the stack):
#   s0 = number of words        s1 = number of lines read so far
#   s2 = pointer into the line  s3 = end of the current word
#   s4 = length of the current word
# The input line buffer (96 bytes) lives on the stack at 0(sp).

        .text
p61_main:
        addi    sp, sp, -128
        sw      ra, 124(sp)
        sw      s0, 120(sp)
        sw      s1, 116(sp)
        sw      s2, 112(sp)
        sw      s3, 108(sp)
        sw      s4, 104(sp)

        li      t0, SCREEN_CLEAR        # clear the screen (cursor goes to 0)
        sw      zero, 0(t0)
        li      s0, 0                   # words = 0
        li      s1, 0                   # lines = 0

p61_line_loop:
        li      t0, 4
        bge     s1, t0, p61_done        # at most 4 lines
        mv      a0, sp                  # buffer
        li      a1, 96
        call    rcv_read_line
        beqz    a0, p61_done            # empty line ends the input
        addi    s1, s1, 1

        li      t0, SCREEN_CURSOR       # a new input line starts at a row start
        lw      t1, 0(t0)
        andi    t1, t1, 15
        beqz    t1, p61_line_start
        li      t0, SCREEN_CHAR
        li      t1, 10
        sw      t1, 0(t0)
p61_line_start:
        mv      s2, sp                  # s2 = start of the line

p61_word_loop:
        lbu     t0, 0(s2)
        beqz    t0, p61_line_loop       # end of the line
        li      t1, ' '
        bne     t0, t1, p61_word_start
        addi    s2, s2, 1               # skip spaces
        j       p61_word_loop

p61_word_start:
        mv      s3, s2                  # find the end of the word
p61_len_loop:
        lbu     t0, 0(s3)
        beqz    t0, p61_len_done
        li      t1, ' '
        beq     t0, t1, p61_len_done
        addi    s3, s3, 1
        j       p61_len_loop
p61_len_done:
        sub     s4, s3, s2              # length of the word

        li      t0, SCREEN_CURSOR       # column = cursor mod 16
        lw      t1, 0(t0)
        andi    t1, t1, 15
        beqz    t1, p61_put_word        # at the start of a row: no separator
        add     t2, t1, s4
        addi    t2, t2, 1               # column + 1 + length
        li      t3, 16
        bgt     t2, t3, p61_wrap
        li      t0, SCREEN_CHAR         # fits: one space
        li      t3, ' '
        sw      t3, 0(t0)
        j       p61_put_word
p61_wrap:
        li      t0, SCREEN_CHAR         # does not fit: new row
        li      t3, 10
        sw      t3, 0(t0)

p61_put_word:
        li      t0, SCREEN_CHAR
p61_char_loop:
        beq     s2, s3, p61_word_done
        lbu     t1, 0(s2)
        sw      t1, 0(t0)
        addi    s2, s2, 1
        j       p61_char_loop
p61_word_done:
        addi    s0, s0, 1
        j       p61_word_loop

p61_done:
        la      a0, p61_msg
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_dec
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
p61_msg:
        .asciz  "words: "
        .align  2
