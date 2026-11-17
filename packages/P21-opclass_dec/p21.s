# P21 program - palindrome checker
# Reads a word, prints "<word> is a palindrome" or "<word> is not a palindrome".
# Rules: start at the label p21_main and finish with ret; every label you
# create starts with p21_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

        .text
p21_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)
        addi    sp, sp, -128         # line buffer on the stack
        mv      s0, sp               # s0 = buffer start
        li      s1, 0                # s1 = length

p21_read:                            # read chars until newline / EOF
        li      t0, 127
        bge     s1, t0, p21_check
        jal     ra, rcv_getc
        bltz    a0, p21_check        # EOF / error
        beqz    a0, p21_check
        li      t0, 10
        beq     a0, t0, p21_check    # '\n'
        li      t0, 13
        beq     a0, t0, p21_check    # '\r'
        add     t1, s0, s1
        sb      a0, 0(t1)
        addi    s1, s1, 1
        j       p21_read

p21_check:
        add     t1, s0, s1
        sb      zero, 0(t1)          # terminate the word with 0
        mv      t0, s0               # t0 = first char
        addi    t1, t1, -1           # t1 = last char
p21_cmp:
        bgeu    t0, t1, p21_yes      # met/crossed -> palindrome
        lbu     t2, 0(t0)
        lbu     t3, 0(t1)
        bne     t2, t3, p21_no
        addi    t0, t0, 1
        addi    t1, t1, -1
        j       p21_cmp

p21_yes:
        la      s2, p21_msg_yes
        j       p21_print
p21_no:
        la      s2, p21_msg_no
p21_print:
        mv      a0, s0               # print the word
        jal     ra, rcv_puts
        mv      a0, s2               # print " is (not) a palindrome"
        jal     ra, rcv_puts

        addi    sp, sp, 128
        lw      s2, 0(sp)
        lw      s1, 4(sp)                                                                                
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p21_msg_yes:
        .asciz  " is a palindrome\n"
p21_msg_no:
        .asciz  " is not a palindrome\n"
        .align  2
