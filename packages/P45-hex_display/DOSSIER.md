# P45 Hex display scanner - dossier

## U1 Digital logic

Let `q1 q0` be the two-bit position of the four-digit Digital scanner.
Both D flip-flops share the rising edge of `clk`. The reset is synchronous:
when `rst=1`, the next state is `00`; asserting reset between edges does
not immediately change the state.

| Present q1q0 | Next q1q0 when rst=0 | anode[3:0] | Selected value bits |
|---|---|---|---|
| 00 | 01 | 0001 | 3..0 |
| 01 | 10 | 0010 | 7..4 |
| 10 | 11 | 0100 | 11..8 |
| 11 | 00 | 1000 | 15..12 |

The simplified next-state equations are
`D0 = NOT(rst) AND NOT(q0)` and
`D1 = NOT(rst) AND (q1 XOR q0)`.
The low bit toggles on every normal edge; the high bit toggles when the
old low bit is one. ANDing with NOT(rst) makes reset take priority.
A decoder implements `anode[0]=~q1 & ~q0`, `anode[1]=~q1 & q0`,
`anode[2]=q1 & ~q0`, and `anode[3]=q1 & q0`.
Only gates, D flip-flops, a multiplexer, a decoder and wiring parts are needed.

## U2 Digital components

The two flip-flops form a modulo-four counter using the gates described above;
there is no built-in counter or adder. A splitter combines their outputs into
a two-bit selector. The 16-bit value splits into four four-bit nibbles.
A four-input multiplexer selects nibble q, while a two-to-four decoder
selects anode q. A splitter packs the decoder outputs into the anode bus.
Both outputs therefore describe the same position.

The Verilog version uses a three-bit modulo-eight position and a 32-bit
value. Its mux selects `value[4*position +: 4]` and its decoder produces
`8'b1 << position`. The position changes on clock edges; the mux is
combinational, so changing value can change digit between edges.

## U3 Data representation

These examples are from the four-digit Digital public test sequence.
The position is the state AFTER the row's clock edge, not before it.

| value (hex) | value (16-bit binary) | Unsigned decimal | Position | digit | anode |
|---|---|---|---|---|---|
| 0013 | 0000 0000 0001 0011 | 19 | 0 | 3 = 0011 | 0001 |
| FFFF | 1111 1111 1111 1111 | 65535 | 2 | F = 1111 | 0100 |
| 8000 | 1000 0000 0000 0000 | 32768 | 1 | 0 = 0000 | 0010 |

Interpreting FFFF and 8000 as signed 16-bit two's-complement numbers gives
-1 and -32768 respectively. The scanner does not perform signed arithmetic:
it selects raw bits, so those signed interpretations do not change its output.
Counter overflow is intentional wraparound. A wrong selector width could
skip positions, and an arithmetic right shift could propagate the sign bit.
The assembly uses logical right shifts and masks the nibble with 15.

BCD is different from ordinary binary: decimal 12345 is binary integer
0x00003039, but packed BCD is 0x00012345. The program repeatedly divides
by ten, places each remainder in successive nibbles, then reads GPIO_SEG
back. Eight BCD digits fit exactly in 32 bits; the specified maximum input
99999999 produces 0x99999999. Zero still produces eight zero digits.

## U4 Computer organisation

The scanner is an output peripheral that runs continuously alongside the
instruction cycle. It does not fetch or decode instructions, and it has no
CPU register write-back path. A store to GPIO_SEG reaches P43 during a
memory/I/O transfer; P43's segment-value register then feeds P45. An LW
can read that register back. P45 supplies the selected nibble to P44,
which converts it to the seven segment signals.

During JALR, P45 continues scanning independently. JALR itself uses fetch,
decode, ALU addition, next-PC selection and link-register write-back;
it performs no data-memory transfer. The RC-V processor executes those
steps in one cycle, using either P22's hardwired controls or P23's control
ROM as selected and checked by P24.

## U5 Processors

A CISC CPU could offer different instructions or addressing modes for
converting a number or accessing the display register, but would still
need a register and output-scanning hardware. RV32I performs the conversion
with explicit shifts, logical operations and calls to a software division
routine because this machine has no DIV instruction.

A stack machine would put intermediate quotient, remainder and packed-value
operands on its operand stack instead of keeping them in named general
registers. Mano's Basic Computer uses an accumulator and dedicated I/O
instructions; RC-V uses general registers and memory-mapped loads/stores.
A GPU could convert many independent values in parallel lanes, but scanning
one physical display has little independent work. The scanner's tiny
counter/mux/decoder continues working without scheduling a CPU instruction
for every displayed position.

The program saves ra and s0-s4 on its stack frame and restores them before
returning. Loop values that must survive library calls stay in saved registers;
a0-a7 and t0-t6 are caller-saved and may be overwritten by those calls.

## U6 Memory and I/O

P45 has no bus-address, read-enable or write-enable input. P43 owns the
memory-mapped display register: GPIO_SEG is at 0x00020084, slot 2 register 1.
P31 decodes the address, P43 accepts the store data, and P33 supplies the
readback through the CPU's load path. P45 receives the stored 32-bit value
through a direct wire, not through an additional memory read.

The program writes packed BCD with SW, reads it with LW, and prints the
readback followed by a software description of all eight scan positions.
Keyboard and terminal library routines use status polling (programmed I/O).
The printed scan lines illustrate the scanner's selections; they do not
sample the hardware's instantaneous internal position. P45 neither raises
an interrupt nor requests DMA or accesses a cache.

## E1 Instruction trace: JALR

A short isolated example was linked with the normal P45 wrapper and runtime
and executed using the repository's `rcv.progrun` trace. This keeps the example
small enough to follow; addresses are for this example's link, not the final
program's link. It saves the caller's ra, jumps through t0, then returns.

```asm
        .text
p45_main:
        addi sp, sp, -16
        sw ra, 12(sp)
        la t0, p45_trace_target
        jalr ra, 0(t0)
        lw ra, 12(sp)
        addi sp, sp, 16
        ret
p45_trace_target:
        ret
```

The simulator trace contains these consecutive instructions:

```text
    54 0000023c 25028293  x5=0x00000250
    55 00000240 000280e7  x1=0x00000244
    56 00000250 00008067
    57 00000244 00c12083  x1=0x00000134
```

| Stage / blocks | Main signals for instruction 000280E7 |
|---|---|
| Fetch: P14, P30, P03 | PC=00000240; instruction=000280E7; PC+4=00000244 |
| Fields: P17, P21 | opcode=1100111; funct3=000; rs1=x5; rd=x1; is_jalr=1 |
| Control: P22/P23, P24 | ctrl=5102; regwrite=1; bsel_imm=1; wbsel=2; is_jalr=1; no memory read/write |
| Immediate: P18, P20 | I-immediate=00000000; immsel=0 chooses that immediate |
| Register read: P12, P13 | rs1 value x5=00000250; rs2 field is zero and is unused |
| Operands: P26 | ALU A=00000250 from rs1; B=00000000 from immediate |
| Execute: P10, P01, P08 | ALU operation ADD; ALU result=00000250 |
| Next PC: P16, P15 | JALR selects (ALU result AND FFFFFFFE)=00000250 |
| Write-back: P25, P11, P12 | select PC+4; write enable for x1; x1 becomes 00000244 |
| State update: P14 | on the rising edge PC becomes 00000250 |

P02 also computes PC+immediate=00000240, but JALR selects the ALU's
rs1-relative target instead. P09's branch comparison is unused. P40 sees
a legal instruction and P39 does not request a trap (interrupts are disabled
in this example). P27-P34 carry no architectural data-memory transaction
for JALR. P37/P38 perform no CSR update. The target's `ret` is
`jalr x0,0(ra)`, so it returns to 00000244 without writing a link register.
Clearing target bit 0 is required even though this example's target is already even.

To reproduce, save the small example as a temporary .s file and run, from
`tools/`: `python3 -m rcv.progrun 45 /tmp/p45-jalr.s --trace`.

## E2 Neighbour review

Required partners: P44 (Seven-segment decoder) and P46 (Timer).
Actual review-comment links are still pending; no review is claimed here.
Before final hand-in, review each partner's pull request and replace the
pending entries with links to the comments actually posted.

- P44 review-comment link: pending.
- P46 review-comment link: pending.

Useful checks for P44: its gfedcba outputs must be active high; check 0,
A and F against the specification. Useful checks for P46: verify reset,
compare-match flag persistence, flag clearing and interrupt-enable behaviour.
These are review prompts, not completed reviews or reported defects.

## E3 Where my block sits

P45 sits in the I/O component layer. P43's 32-bit display register feeds
its value input; its own clocked position selects the digit and the anode.
P44 decodes that digit into seven-segment signals while the anode output
selects which display position is active.

## E4 Syllabus map

Checked topics are used in the implementation or explicitly explained above.
Unchecked topics are outside the work performed here.

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [x] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
