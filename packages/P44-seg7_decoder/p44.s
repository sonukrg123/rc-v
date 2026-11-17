# P44 program: Seven-segment codes from a table
# Read a line of hex digits (0-9, A-F, a-f, at most 32).
# For each digit print: character as typed, " -> ", segment code as two hex digits.

        .text
p44_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        # Read input line into p44_buf (capacity 64 bytes)
        la      a0, p44_buf
        li      a1, 64
        call    rcv_read_line

        la      s0, p44_buf
        la      s1, p44_table
        la      s2, p44_arrow

p44_loop:
        lbu     t0, 0(s0)
        beqz    t0, p44_done

        # Check '0'..'9'
        li      t1, 48                  # '0'
        blt     t0, t1, p44_next
        li      t1, 57                  # '9'
        bgt     t0, t1, p44_check_upper
        addi    t2, t0, -48
        j       p44_convert_ok

p44_check_upper:
        # Check 'A'..'F'
        li      t1, 65                  # 'A'
        blt     t0, t1, p44_next
        li      t1, 70                  # 'F'
        bgt     t0, t1, p44_check_lower
        addi    t2, t0, -55
        j       p44_convert_ok

p44_check_lower:
        # Check 'a'..'f'
        li      t1, 97                  # 'a'
        blt     t0, t1, p44_next
        li      t1, 102                 # 'f'
        bgt     t0, t1, p44_next
        addi    t2, t0, -87

p44_convert_ok:
        # 1. Print character as typed
        mv      a0, t0
        call    rcv_putc

        # 2. Print separator " -> "
        mv      a0, s2
        call    rcv_puts

        # 3. Look up segment code from table and print as 2 hex digits
        add     t3, s1, t2
        lbu     a0, 0(t3)
        call    p44_print_hex2

        # 4. Print newline
        call    rcv_newline

p44_next:
        addi    s0, s0, 1
        j       p44_loop

p44_done:
        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

p44_print_hex2:
        addi    sp, sp, -8
        sw      ra, 4(sp)
        sw      s0, 0(sp)
        mv      s0, a0

        # Print upper nibble
        srli    a0, s0, 4
        andi    a0, a0, 15
        call    p44_nibble_to_ascii
        call    rcv_putc

        # Print lower nibble
        andi    a0, s0, 15
        call    p44_nibble_to_ascii
        call    rcv_putc

        lw      s0, 0(sp)
        lw      ra, 4(sp)
        addi    sp, sp, 8
        ret

p44_nibble_to_ascii:
        li      t0, 10
        blt     a0, t0, p44_digit
        addi    a0, a0, 55              # 10..15 -> 'A'..'F'
        ret
p44_digit:
        addi    a0, a0, 48              # 0..9 -> '0'..'9'
        ret

        .rodata
p44_arrow:
        .asciz  " -> "
        .align  2

p44_table:
        .byte   0x3F, 0x06, 0x5B, 0x4F
        .byte   0x66, 0x6D, 0x7D, 0x07
        .byte   0x7F, 0x6F, 0x77, 0x7C
        .byte   0x39, 0x5E, 0x79, 0x71
        .align  2

        .data
p44_buf:
        .space  64
