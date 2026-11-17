# P60 program - see README.md for the task.
# Rules: start at the label p60_main and finish with ret; every label you
# create starts with p60_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

# Registers kept across library calls (s registers):
#   s0 = pointer to the current character    s1 = end of the line
#   s2 = running XOR of the parity bits      s3 = current character
#   s4 = parity bit of the current character

        .text
p60_main:
                addi    sp, sp, -80             # 48-byte line buffer + saved registers
        sw      ra, 76(sp)
        sw      s0, 72(sp)
        sw      s1, 68(sp)
        sw      s2, 64(sp)
        sw      s3, 60(sp)
        sw      s4, 56(sp)
 
        mv      a0, sp                  # buffer = bottom of our stack frame
        li      a1, 41                  # room for 40 characters
        call    rcv_read_line           # a0 = length of the line
        mv      s0, sp                  # s0 = first character
        add     s1, sp, a0              # s1 = just past the last character
        li      s2, 0                   # running parity = 0
 
p60_loop:
        bgeu    s0, s1, p60_done        # no characters left -> finish
        lbu     s3, 0(s0)               # s3 = the character
 
        li      t1, PARITY_DATA
        sw      s3, 0(t1)               # give it to the parity device
        li      t1, PARITY_PARITY
        lw      s4, 0(t1)               # read the PARITY register
        andi    s4, s4, 1               # bit 0 = parity of byte 0 (our character)
        xor     s2, s2, s4              # fold it into the line parity
 
        mv      a0, s3                  # print the character
        call    rcv_putc
        li      a0, 32                  # space
        call    rcv_putc
        srli    a0, s3, 4               # high hex digit
        call    p60_putnib
        andi    a0, s3, 15              # low hex digit
        call    p60_putnib
        li      a0, 32                  # space
        call    rcv_putc
        addi    a0, s4, 48              # parity bit as '0' or '1'
        call    rcv_putc
        call    rcv_newline
 
        addi    s0, s0, 1               # next character
        j       p60_loop
 
p60_done:
        la      a0, p60_msg             # "line parity: "
        call    rcv_puts
        addi    a0, s2, 48              # the final bit as '0' or '1'
        call    rcv_putc
        call    rcv_newline
 
        lw      s4, 56(sp)
        lw      s3, 60(sp)
        lw      s2, 64(sp)
        lw      s1, 68(sp)
        lw      s0, 72(sp)
        lw      ra, 76(sp)
        addi    sp, sp, 80
        ret

# p60_putnib: print the value 0..15 in a0 as one hex digit (0-9, A-F)
p60_putnib:
        addi    sp, sp, -4
        sw      ra, 0(sp)
        li      t0, 10
        blt     a0, t0, p60_digit       # below 10 -> a decimal digit
        addi    a0, a0, 55              # 10..15 -> 'A'..'F'  ('A' - 10 = 55)
        j       p60_emit
p60_digit:
        addi    a0, a0, 48              # 0..9 -> '0'..'9'
p60_emit:
        call    rcv_putc
        lw      ra, 0(sp)
        addi    sp, sp, 4
        ret
 
        .rodata
p60_msg:
        .asciz  "line parity: "
        .align  2
