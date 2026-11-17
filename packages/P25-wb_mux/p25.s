# P25 program - String routines
# Reads two words, prints their lengths, joins them, and compares them.
# All labels defined in this file use the p25_ prefix.

        .text
p25_main:
        # Save return address and every saved register used by this routine.
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)
        sw      s5, 4(sp)

        # Read the two input words (30 characters + null terminator).
        la      s0, p25_word1
        mv      a0, s0
        li      a1, 31
        call    rcv_read_line

        la      s1, p25_word2
        mv      a0, s1
        li      a1, 31
        call    rcv_read_line

        # Calculate both lengths.
        mv      a0, s0
        call    p25_len
        mv      s3, a0

        mv      a0, s1
        call    p25_len
        mv      s4, a0

        # Print length 1.
        la      a0, p25_label_len1
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_udec
        call    rcv_newline

        # Print length 2.
        la      a0, p25_label_len2
        call    rcv_puts
        mv      a0, s4
        call    rcv_print_udec
        call    rcv_newline

        # Copy word 1, then append word 2 at the returned end address.
        mv      a0, s0
        la      a1, p25_joined
        call    p25_copy
        mv      s5, a0

        mv      a0, s1
        mv      a1, s5
        call    p25_copy

        # Print the joined word.
        la      a0, p25_label_joined
        call    rcv_puts
        la      a0, p25_joined
        call    rcv_puts
        call    rcv_newline

        # Compare the original words and print yes/no.
        mv      a0, s0
        mv      a1, s1
        call    p25_equal
        beqz    a0, p25_print_no

        la      a0, p25_label_equal_yes
        call    rcv_puts
        j       p25_main_done

p25_print_no:
        la      a0, p25_label_equal_no
        call    rcv_puts

p25_main_done:
        # Restore saved registers and return to the caller.
        lw      s5, 4(sp)
        lw      s4, 8(sp)
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret

# p25_len(a0 = string address) -> a0 = length
p25_len:
        mv      t0, a0
        li      t1, 0
p25_len_loop:
        lbu     t2, 0(t0)
        beqz    t2, p25_len_done
        addi    t1, t1, 1
        addi    t0, t0, 1
        j       p25_len_loop
p25_len_done:
        mv      a0, t1
        ret

# p25_copy(a0 = source, a1 = destination) -> a0 = end address
# The null terminator is copied too; the returned address points to it.
p25_copy:
        mv      t0, a0
        mv      t1, a1
p25_copy_loop:
        lbu     t2, 0(t0)
        sb      t2, 0(t1)
        beqz    t2, p25_copy_done
        addi    t0, t0, 1
        addi    t1, t1, 1
        j       p25_copy_loop
p25_copy_done:
        mv      a0, t1
        ret

# p25_equal(a0 = first string, a1 = second string) -> a0 = 1 if equal, else 0
p25_equal:
        mv      t0, a0
        mv      t1, a1
p25_equal_loop:
        lbu     t2, 0(t0)
        lbu     t3, 0(t1)
        bne     t2, t3, p25_equal_false
        beqz    t2, p25_equal_true
        addi    t0, t0, 1
        addi    t1, t1, 1
        j       p25_equal_loop
p25_equal_true:
        li      a0, 1
        ret
p25_equal_false:
        li      a0, 0
        ret

        .rodata
p25_label_len1:
        .asciz  "length 1: "
p25_label_len2:
        .asciz  "length 2: "
p25_label_joined:
        .asciz  "joined: "
p25_label_equal_yes:
        .asciz  "equal: yes\n"
p25_label_equal_no:
        .asciz  "equal: no\n"
        .align  2

        .data
        .align  2
p25_word1:
        .space  31
p25_word2:
        .space  31
p25_joined:
        .space  61
