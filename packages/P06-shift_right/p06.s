# P06 program - Arithmetic and logical right shift
# Rules: start at the label p06_main and finish with ret; every label you
# create starts with p06_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

        .text
p06_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        call    rcv_read_dec
        mv      s0, a0

        srai    s1, s0, 1
        srli    s2, s0, 1

        # Line 1: N       = <s0> (<hex s0>)
        la      a0, p06_str_n
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_dec
        la      a0, p06_str_op
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_hex
        la      a0, p06_str_cp
        call    rcv_puts

        # Line 2: N sra 1 = <s1> (<hex s1>)
        la      a0, p06_str_sra
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_dec
        la      a0, p06_str_op
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_hex
        la      a0, p06_str_cp
        call    rcv_puts

        # Line 3: N srl 1 = <s2> (<hex s2>)
        la      a0, p06_str_srl
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        la      a0, p06_str_op
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_hex
        la      a0, p06_str_cp
        call    rcv_puts

        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p06_str_n:
        .asciz  "N       = "
p06_str_sra:
        .asciz  "N sra 1 = "
p06_str_srl:
        .asciz  "N srl 1 = "
p06_str_op:
        .asciz  " ("
p06_str_cp:
        .asciz  ")\n"
        .align  2
