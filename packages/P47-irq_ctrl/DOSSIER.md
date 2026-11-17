# P47 Interrupt controller - dossier

## U1 Digital logic
Part: the priority encoder. Let m0..m4 be the masked lines (`m_i = lines_i AND mask_i`).

| m4 m3 m2 m1 m0 | irq | cause |
|---|---|---|
| 0 0 0 0 0 | 0 | 31 |
| x x x x 1 | 1 | 0 |
| x x x 1 0 | 1 | 1 |
| x x 1 0 0 | 1 | 2 |
| x 1 0 0 0 | 1 | 3 |
| 1 0 0 0 0 | 1 | 4 |

Simplified expressions (p_i = "source i is the winner", none = NOT irq):
- irq = m0 + m1 + m2 + m3 + m4
- p1 = m0'·m1, p2 = m0'·m1'·m2, p3 = m0'·m1'·m2'·m3, p4 = m0'·m1'·m2'·m3'·m4
- cause[0] = p1 + p3 + none, cause[1] = p2 + p3 + none, cause[2] = p4 + none, cause[3] = cause[4] = none

Gates used: AND, OR, NOT only (no flip-flops, the circuit is purely combinational).

## U2 Digital components
Two splitters break the 5-bit `lines` and `mask` buses into single bits. Five AND gates do the masking. An OR chain makes `irq`. A chain of AND gates with NOT gates (m0', m0'·m1', ...) builds the "nobody with a lower number is active" terms, which is the priority encoder. OR gates combine the terms into cause bits 0-2, and a splitter joins the five cause bits into one 5-bit output. No adders, muxes, registers or memory are needed in the Digital part. In the Verilog version the MASK register and the SWI flag are flip-flops.

## U3 Data representation
| lines | mask | masked (binary) | irq | cause (dec / hex / binary) |
|---|---|---|---|---|
| 5 = 0x05 = 00101 | 6 = 0x06 = 00110 | 00100 | 1 | 2 / 0x02 / 00010 |
| 0 = 0x00 = 00000 | 31 = 0x1F = 11111 | 00000 | 0 | 31 / 0x1F / 11111 |
| 24 = 0x18 = 11000 | 16 = 0x10 = 10000 | 10000 | 1 | 4 / 0x04 / 00100 |

Everything is unsigned (source numbers, no negative values), so sign extension does not matter in the Digital part. Possible mistakes: 31 (all ones) is a valid 5-bit value, so software must check `irq` or PENDING before trusting CAUSE. In the Verilog block, the 5-bit values are zero-extended into the 32-bit `rdata`; sign-extending them would give wrong values.

## U4 Computer organisation
The block works in the **interrupt check** step of the instruction cycle: if an enabled interrupt is pending (`irq`, with mstatus.MIE = 1), the instruction is not executed, mepc <- PC, mcause <- 0x80000010 + source, MIE <- 0 and PC <- mtvec. It is needed by `csrw/csrs/csrc` (set mtvec, MIE), by loads/stores to the device registers (PENDING, MASK, CAUSE, SWI), and by `mret`, which returns from the handler.

## U5 Processors
A CISC processor would often use a microcoded interrupt sequence (and may use vectored interrupts, where hardware jumps straight to a per-source address). A stack machine would push the return address and flags onto its hardware stack on every interrupt. A GPU mostly avoids interrupts and uses many parallel threads, with the host polling or receiving a completion signal. RC-V (like Mano's Basic Computer) has one shared handler address; software reads CAUSE to find the source.

## U6 Memory and I/O
P47 is an I/O device in slot 4 (0x0002_0100): PENDING (reg 0), MASK (reg 1), CAUSE (reg 2), SWI (reg 3), and register 15 reads 47. The CPU accesses it with ordinary `lw`/`sw`, which the address decoder (P31) and the I/O bus (P33) route to the device. This is interrupt-driven I/O: devices (timer, keyboard, DMA, stack guard) raise `lines`, so the CPU does not need to poll them.

## E1 Instruction trace: BNE (not taken)
Example: `bne a0, a1, p47_skip` at PC = 0x100 with a0 = a1 = 5 (so not taken), encoded 0x00B51463.

| Block | What it does / value |
|---|---|
| P14 PC | PC = 0x0000_0100 |
| P30 ROM | outputs instr = 0x00B51463 |
| P17 fields | opcode 1100011, rs1 = 10, rs2 = 11, funct3 = 001 |
| P21 / P22 / P23 / P24 | class BRANCH, control word 0x0028 (is_branch = 1, immsel = B, no regwrite, no memory) |
| P19 / P20 | B-immediate = 8, selected |
| P13 register read | rs1 = 5, rs2 = 5 |
| P09 branch comparator | a == b, so for BNE the condition is false |
| P02 target adder | target = PC + 8 = 0x108 (computed but not used) |
| P03 PC incrementer | PC + 4 = 0x104 |
| P16 next-PC logic | is_branch AND taken = 0, so pcsel = 0 |
| P15 next PC | selects PC + 4 |
| P14 PC | PC <- 0x0000_0104 |
| Register file / RAM / I/O | nothing written (regwrite = 0, memwrite = 0) |

(Values are an example; replace them with the numbers from your own `--trace` run if you use a different instruction.)

## E2 Neighbour review
- P46 (Timer) review: <paste link here>
- P48 (DMA controller) review: <paste link here>

## E3 Where my block sits
P47 is in the I/O / interrupt layer. It is fed by the device lines (timer P46, keyboard P42, DMA P48, stack guard P55) and by the CPU's register writes (MASK, SWI). Its `irq` and `cause` outputs go to the trap controller (P39) and the CSR file (P37), and the latency meter (P62) also uses them.

## E4 Syllabus map
- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [ ] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [ ] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
