# P24 program - see README.md for the task.
# Rules: start at the label p24_main and finish with ret; every label you
# create starts with p24_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).
# p24 program - Sieve of Eratosthenes

        .data
p24_sieve:
        .space 504

        .rodata
p24_primes_msg:
        .asciz "primes:"
p24_count_msg:
        .asciz "count: "
        .text
p24_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)

        # TODO: your program

                # Read N
        call    rcv_read_dec
        mv      s0, a0

        # Load sieve array address
        la      s1, p24_sieve

        # Clear array from 0 to N
        li      s2, 0

p24_clear_loop:
        blt     s0, s2, p24_clear_done

        add     t0, s1, s2
        sb      zero, 0(t0)

        addi    s2, s2, 1
        j       p24_clear_loop

p24_clear_done:
        
        # Print primes heading
        la      a0, p24_primes_msg
        call    rcv_puts

        # Initialise prime counter and index
        li      s2, 2
        li      s4, 0

p24_prime_loop:
        # Stop when i > N
        blt     s0, s2, p24_primes_done

        # Check whether i is marked
        add     t0, s1, s2
        lbu     t1, 0(t0)
        bnez    t1, p24_next_number

        # i is prime: increase count
        addi    s4, s4, 1

        # Print a space and the prime
        li      a0, ' '
        call    rcv_putc
        mv      a0, s2
        call    rcv_print_udec

        # Start marking multiples at 2*i
        slli    s3, s2, 1

p24_mark_loop:
        blt     s0, s3, p24_next_number

        add     t0, s1, s3
        li      t1, 1
        sb      t1, 0(t0)

        add     s3, s3, s2
        j       p24_mark_loop

p24_next_number:
        addi    s2, s2, 1
        j       p24_prime_loop
p24_primes_done:
        call    rcv_newline

        la      a0, p24_count_msg
        call    rcv_puts

        mv      a0, s4
        call    rcv_print_udec
        call    rcv_newline

        lw      s4, 8(sp)
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret
       
