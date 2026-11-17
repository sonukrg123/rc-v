# P24 Control selector and checker - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
The checker compares the two control words bit by bit with XOR, then ORs the results.

Truth table for one bit of the checker (mismatch_i = hw_i XOR rom_i):

| hw_i | rom_i | mismatch_i |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

Full output: mismatch = mismatch_0 OR mismatch_1 OR ... OR mismatch_15.

Selector, one bit: ctrl_i = (NOT use_rom AND hw_i) OR (use_rom AND rom_i).

Gates used: XOR gates and one 16-input OR gate, plus 2-to-1 multiplexers for the
selector. No flip-flops are needed because the block is purely combinational.

## U2 Digital components
- A 16-bit 2-to-1 multiplexer: input 0 = ctrl_hw, input 1 = ctrl_rom, selector =
  use_rom, output = ctrl.
- A 16-bit XOR gate that takes ctrl_hw and ctrl_rom.
- A splitter that separates the 16-bit XOR result into 16 single bits.
- A 16-input OR gate that takes those 16 bits; its output is mismatch.

There are no adders, registers or memory. I tested the circuit by hand with several
input combinations, including a difference only in bit 15.

## U3 Data representation
The control word is 16 bits wide (see the control word table in docs/ARCHITECTURE.md).

| ctrl_hw | ctrl_rom | binary of hw | decimal of hw | XOR | mismatch |
|---|---|---|---|---|---|
| 0x5000 (OP-IMM) | 0x5000 | 0101 0000 0000 0000 | 20480 | 0x0000 | 0 |
| 0x5000 (OP-IMM) | 0x4000 (OP) | 0101 0000 0000 0000 | 20480 | 0x1000 | 1 |
| 0x4181 (SYSTEM) | 0x4181 | 0100 0001 1000 0001 | 16769 | 0x0000 | 0 |

In row 2 the XOR is 0x1000, so only bit 12 (bsel_imm) differs, and mismatch = 1. With
use_rom = 1 the output ctrl would be 0x4000.

Bit 15 of the control word is always 0, so as a signed 16-bit number every control
word is positive. The block does no arithmetic, so there is no overflow. The risk is
bit width: a block that drops or sign-extends a bit would corrupt a control bit, and a
missing bit 15 in the OR would hide a difference there.

## U4 Computer organisation
The block works in the decode step of the instruction cycle. P22 (hardwired) and P23
(control ROM) each produce the control word, and P24 chooses one and checks that they
agree. The control word then steers execute, memory and write-back. Every instruction
needs it, because every instruction needs a control word.

## U5 Processors
RC-V is single-cycle and can use hardwired or microprogrammed control. In Mano's Basic
Computer the control comes from the decoder outputs D0-D7 and the timing signals
T0-T6, while RC-V does it in one clock. A CISC processor usually uses microprogrammed
control, with a control ROM that steps through several micro-instructions per
instruction, so it would lean on the ROM path. A stack machine needs fewer control
bits because operands are implicit on the stack, so there are no register fields to
select. A GPU applies one control word to many parallel lanes at once.

## U6 Memory and I/O
My block does not move data itself. It outputs control bits, including memread (bit 10)
and memwrite (bit 9), which tell the bus arbiter (P34) and address decoder (P31)
whether the instruction is a load or a store. The data travels through P27, P29, P33,
P32 and P28.

## E1 Instruction trace: SRAI
Example: `srai x5, x6, 2` with x6 = 0xFFFFFFF0 (-16).

Encoding: imm[11:0] = 0x402 (funct7 = 0100000, shamt = 2), rs1 = 6, funct3 = 101,
rd = 5, opcode = 0010011, so the instruction word is 0x40235293.

| Step | Block | Value |
|---|---|---|
| Fetch | P14 PC, P30 ROM | instr = 0x40235293 |
| Decode | P17 fields | opcode 0x13, rd 5, funct3 5, rs1 6, imm field 0x402 |
| | P21 class decoder | OP-IMM |
| | P22 and P23 into P24 | control word 0x5000 (regwrite = 1, bsel_imm = 1, wbsel = 0, immsel = 0), mismatch = 0 |
| | P18, P19, P20 | I-type immediate 0x00000402 |
| | P13 register file | rs1 = x6 = 0xFFFFFFF0 |
| Execute | P26 operand select | A = 0xFFFFFFF0, B = 0x402 (bsel_imm = 1) |
| | P10 ALU control | is_opimm = 1, funct3 = 101, funct7b5 = 1, so aluop = 7 (SRA) |
| | P06 right shifter | sh = B[4:0] = 2, arith = 1, so shr_y = 0xFFFFFFFC |
| | P08 result selector | aluop = 7 selects shr_y, so y = 0xFFFFFFFC, zero = 0 |
| Memory | P27, P34, P31, P29 | not used (memread = memwrite = 0) |
| Write back | P25 | wbsel = 0 selects the ALU result; P11 and P12 write x5 = 0xFFFFFFFC |
| Next PC | P03, P16, P15, P14 | no branch or jump, so PC + 4 |

## E2 Neighbour review
My review partners are P23 (Microprogrammed control) and P25 (Write-back selector).

- P23 (program, `p23.s`):
  - https://github.com/campus-sutra/rc-v/pull/40/changes#paneldiscussion_r4575621609
  - https://github.com/campus-sutra/rc-v/pull/40/changes#paneldiscussion_r4575625358
  - https://github.com/campus-sutra/rc-v/pull/40/changes#paneldiscussion_r4575626585
- P25: not reviewed yet. As of 15 Nov 2026 the owner had not handed in any files to
  review.

## E3 Where my block sits
My block is in the control layer. It is fed by the hardwired control unit (P22), the
microprogrammed control ROM (P23) and the use_rom select. Its ctrl output goes to the
datapath blocks that use control bits: operand select, ALU control, memory access,
write-back and next-PC logic.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 4).

- [✓] Logic gates, Boolean algebra, K-maps
- [✓] Combinational circuits (adders, decoders, encoders, multiplexers)
- [✓] Flip-flops, registers, counters
- [✓] Memory (RAM, ROM)
- [✓] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [x] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [✓] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
