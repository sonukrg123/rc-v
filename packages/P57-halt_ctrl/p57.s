
# P57 - Halt controller
# Command loop with an exit code

        .text
p57_main:
        # Create stack frame and save registers
        addi    sp, sp, -96
        sw      ra, 92(sp)
        sw      s0, 88(sp)
        sw      s1, 84(sp)
        sw      s2, 80(sp)
        sw      s3, 76(sp)

        li      s0, 0              # command count
        addi    s1, sp, 16         # input buffer (41 bytes)

p57_loop:
        # Read one line, maximum 40 characters
        mv      a0, s1
        li      a1, 41
        call    rcv_read_line
        mv      s2, a0             # line length

        # Ignore empty lines
        beqz    s2, p57_loop

        # Count this command
        addi    s0, s0, 1

        # Read first character
        lbu     s3, 0(s1)

        li      t0, 'h'
        beq     s3, t0, p57_help

        li      t0, 'c'
        beq     s3, t0, p57_count

        li      t0, 'e'
        beq     s3, t0, p57_echo

        li      t0, 'q'
        beq     s3, t0, p57_quit

        # Unknown command
p57_unknown:
        la      a0, p57_unknown_msg
        call    rcv_puts
        mv      a0, s3
        call    rcv_putc
        call    rcv_newline
        j       p57_loop

        # Help command
p57_help:
        la      a0, p57_help_msg
        call    rcv_puts
        call    rcv_newline
        j       p57_loop

        # Count command
p57_count:
        la      a0, p57_count_msg
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_dec
        call    rcv_newline
        j       p57_loop

        # Echo command: print text after "e "
p57_echo:
        li      t0, 2
        blt     s2, t0, p57_echo_empty

        addi    a0, s1, 2
        call    rcv_puts
        call    rcv_newline
        j       p57_loop

p57_echo_empty:
        call    rcv_newline
        j       p57_loop

        # Quit command
p57_quit:
        la      a0, p57_bye_msg
        call    rcv_puts

        mv      a0, s0
        call    rcv_print_dec

        la      a0, p57_commands_msg
        call    rcv_puts
        call    rcv_newline

        # Write command count to CODE register
        li      t0, 0x000203C4
        sw      s0, 0(t0)

        # Restore registers and return
        lw      s3, 76(sp)
        lw      s2, 80(sp)
        lw      s1, 84(sp)
        lw      s0, 88(sp)
        lw      ra, 92(sp)
        addi    sp, sp, 96
        ret

        .rodata

p57_help_msg:
        .asciz  "commands: h help, c count, e <text> echo, q quit"

p57_count_msg:
        .asciz  "count: "

p57_unknown_msg:
        .asciz  "unknown command "

p57_bye_msg:
        .asciz  "bye ("

p57_commands_msg:
        .asciz  " commands)"
        .align  2