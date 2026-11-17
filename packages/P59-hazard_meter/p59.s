# P59 program: load-use hazards
# Rules: start at the label p59_main and finish with ret; every label starts
# with p59_ ; ra and the s registers used are saved on the stack.

        .text
p59_main:
        addi    sp, sp, -96             # 64 bytes for the array + saved registers
        sw      ra, 92(sp)
        sw      s0, 88(sp)
        sw      s1, 84(sp)
        sw      s2, 80(sp)
        sw      s3, 76(sp)
        sw      s4, 72(sp)

        call    rcv_read_dec            # N
        mv      s0, a0                  # s0 = N
        li      s1, 0                   # s1 = index
p59_read:
        bge     s1, s0, p59_read_done
        call    rcv_read_dec            # next number in a0
        slli    t0, s1, 2
        add     t0, t0, sp              # array starts at 0(sp)
        sw      a0, 0(t0)
        addi    s1, s1, 1
        j       p59_read
p59_read_done:

        # ---------- version A ----------
        li      a5, 0x00020440          # HAZARD_BASE
        mv      t0, sp                  # t0 = array
        mv      t2, s0                  # t2 = N
        li      a0, 0                   # sum = 0
        sw      zero, 8(a5)             # CLEAR
p59_loop_a:
        lw      t1, 0(t0)
        add     a0, a0, t1
        addi    t0, t0, 4
        addi    t2, t2, -1
        bnez    t2, p59_loop_a
        lw      a1, 0(a5)               # LOADUSE
        lw      a2, 4(a5)               # RAW1
        mv      s2, a0
        mv      s3, a1
        mv      s4, a2

        la      a0, p59_str_a
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        la      a0, p59_str_lu
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_dec
        la      a0, p59_str_raw
        call    rcv_puts
        mv      a0, s4
        call    rcv_print_dec
        call    rcv_newline

        # ---------- version B ----------
        li      a5, 0x00020440
        mv      t0, sp
        mv      t2, s0
        li      a0, 0
        sw      zero, 8(a5)             # CLEAR
p59_loop_b:
        lw      t1, 0(t0)
        addi    t0, t0, 4
        add     a0, a0, t1
        addi    t2, t2, -1
        bnez    t2, p59_loop_b
        lw      a1, 0(a5)
        lw      a2, 4(a5)
        mv      s2, a0
        mv      s3, a1
        mv      s4, a2

        la      a0, p59_str_b
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        la      a0, p59_str_lu
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_dec
        la      a0, p59_str_raw
        call    rcv_puts
        mv      a0, s4
        call    rcv_print_dec
        call    rcv_newline

        lw      s4, 72(sp)
        lw      s3, 76(sp)
        lw      s2, 80(sp)
        lw      s1, 84(sp)
        lw      s0, 88(sp)
        lw      ra, 92(sp)
        addi    sp, sp, 96
        ret

        .rodata
p59_str_a:
        .asciz  "version A: sum="
p59_str_b:
        .asciz  "version B: sum="
p59_str_lu:
        .asciz  " loaduse="
p59_str_raw:
        .asciz  " raw1="
        .align  2
