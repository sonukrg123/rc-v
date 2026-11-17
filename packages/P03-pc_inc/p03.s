# P03 program - Bubble sort

        .text
        .globl p03_main
p03_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        la      s0, p03_arr         # s0 = array base address
        li      s1, 0               # s1 = count of numbers (n)
        li      s2, 20              # s2 = max 20 numbers

p03_read_loop:
        call    rcv_read_dec
        beqz    a0, p03_read_done
        bge     s1, s2, p03_read_loop
        slli    t0, s1, 2
        add     t1, s0, t0
        sw      a0, 0(t1)
        addi    s1, s1, 1
        j       p03_read_loop

p03_read_done:
        li      t0, 1
        ble     s1, t0, p03_sort_done

        li      t0, 0               # i = 0
        addi    t2, s1, -1          # n - 1

p03_outer_loop:
        bge     t0, t2, p03_sort_done
        li      t1, 0               # j = 0
        sub     t3, t2, t0          # n - 1 - i

p03_inner_loop:
        bge     t1, t3, p03_outer_next
        slli    t4, t1, 2
        add     t4, s0, t4
        lw      t5, 0(t4)
        lw      t6, 4(t4)
        ble     t5, t6, p03_no_swap
        sw      t6, 0(t4)
        sw      t5, 4(t4)

p03_no_swap:
        addi    t1, t1, 1
        j       p03_inner_loop

p03_outer_next:
        addi    t0, t0, 1
        j       p03_outer_loop

p03_sort_done:
        la      a0, p03_str_sorted
        call    rcv_puts

        li      s2, 0               # print index i = 0

p03_print_loop:
        bge     s2, s1, p03_print_done
        li      a0, 32              # ASCII space ' '
        call    rcv_putc
        slli    t0, s2, 2
        add     t0, s0, t0
        lw      a0, 0(t0)
        call    rcv_print_dec
        addi    s2, s2, 1
        j       p03_print_loop

p03_print_done:
        call    rcv_newline

        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p03_str_sorted:
        .asciz "sorted:"
        .align 2

        .data
        .align 2
p03_arr:
        .space 80
