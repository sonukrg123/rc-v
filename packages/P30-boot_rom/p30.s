# P30 program: String table in ROM
# Reads decimal indexes until 9. For 0-4 prints
#   string <i>: <text> (offset <8 hex digits>)
# otherwise prints "no such string".
# Rules: start at p30_main, end with ret, every label starts with p30_,
# save ra (and any s registers used) on the stack.

        .text
p30_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)               # s0 = index just read
        sw      s1, 4(sp)               # s1 = address of the chosen string

p30_loop:
        call    rcv_read_dec            # a0 = number read
        li      t0, 9
        beq     a0, t0, p30_done        # 9 ends the input
        li      t0, 4
        bgtu    a0, t0, p30_bad         # unsigned compare: also catches negatives

        mv      s0, a0                  # keep index (calls clobber a0/t regs)

        la      a0, p30_txt_string
        call    rcv_puts                # "string "
        mv      a0, s0
        call    rcv_print_udec          # the index
        la      a0, p30_txt_colon
        call    rcv_puts                # ": "

        la      t0, p30_table
        slli    t1, s0, 2               # index * 4 (each entry is a .word)
        add     t0, t0, t1
        lw      s1, 0(t0)               # s1 = table[index] = string address
        mv      a0, s1
        call    rcv_puts                # the string text

        la      a0, p30_txt_offset
        call    rcv_puts                # " (offset "
        la      t0, p30_table
        lw      t0, 0(t0)               # address of the first string
        sub     a0, s1, t0              # offset from the first string
        call    rcv_print_hex           # 8 hex digits
        la      a0, p30_txt_end
        call    rcv_puts                # ")\n"
        j       p30_loop

p30_bad:
        la      a0, p30_txt_none
        call    rcv_puts
        j       p30_loop

p30_done:
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
        .align  2
p30_table:
        .word   p30_str0
        .word   p30_str1
        .word   p30_str2
        .word   p30_str3
        .word   p30_str4

# the five strings must sit directly after each other, in this order
p30_str0:       .asciz  "ROM"
p30_str1:       .asciz  "RAM"
p30_str2:       .asciz  "UART"
p30_str3:       .asciz  "KEYBOARD"
p30_str4:       .asciz  "TIMER"

p30_txt_string: .asciz  "string "
p30_txt_colon:  .asciz  ": "
p30_txt_offset: .asciz  " (offset "
p30_txt_end:    .asciz  ")\n"
p30_txt_none:   .asciz  "no such string\n"
        .align  2
