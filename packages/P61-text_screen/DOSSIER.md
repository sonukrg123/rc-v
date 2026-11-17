# P61 Text screen - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Part: the next-value logic of the cursor register (6 bits, cursor = row*16 + column).

| rst | clear | newline | put | next cursor |
|---|---|---|---|---|
| 1 | x | x | x | 0 |
| 0 | 1 | x | x | 0 |
| 0 | 0 | 1 | x | (cursor AND 110000) + 010000 |
| 0 | 0 | 0 | 1 | cursor + 1 |
| 0 | 0 | 0 | 0 | cursor (hold) |

Simplified: z = rst OR clear, and next = z ? 0 : (newline ? nl : (put ? inc : cursor)),
where inc = cursor + 1 and nl = (cursor AND 0x30) + 0x10. The priority order
(newline over put) comes from the test table: put=1 and newline=1 together gives 16.
I needed one OR gate, one 6-bit AND (mask 0x30) and a 6-bit D flip-flop
(the checker did not allow the Register part). No K-map was needed because the
priority is built with multiplexers.

## U2 Digital components
- 6-bit D flip-flop: holds the cursor, clocked by clk.
- Two 6-bit adders: one adds 1 (put), the other adds 16 (to the masked value, for newline).
- One 6-bit AND with the constant 0x30: keeps only the row bits, so the column becomes 0.
- Three 2-to-1 multiplexers in a chain: first select = put (hold or +1), second select =
  newline (previous result or next row), third select = rst OR clear (previous result or 0).
- One OR gate for rst/clear, and constants (1, 16, 48, 0).
The multiplexer output goes back to the flip-flop's D input, and Q goes to the
cursor output pin and to the adder and AND inputs.
The Verilog block adds a 64 x 8 memory (one byte per screen cell) with the same cursor logic.

## U3 Data representation
The cursor is unsigned 6 bits, so there is no sign.

| Case | binary | hex | decimal |
|---|---|---|---|
| newline at the last row: 110000 -> 110000 + 010000 = 1 000000 -> 000000 (carry dropped) | 11 0000 -> 00 0000 | 0x30 -> 0x00 | 48 -> 0 |
| newline in the middle: 010001 -> (010001 AND 110000) + 010000 = 100000 | 01 0001 -> 10 0000 | 0x11 -> 0x20 | 17 -> 32 |
| write CURSOR with 0xDD: only wdata[5:0] is used: 1101 1101 -> 01 1101 | 1101 1101 -> 01 1101 | 0xDD -> 0x1D | 221 -> 29 |

Where it can go wrong: overflow of the cursor is wanted (63 + 1 = 0, wrap-around), but
only because the adder is exactly 6 bits wide. A character such as 0x9A is stored as a raw
byte; if a program read it back with `lb` it would be sign-extended to 0xFFFFFF9A, so the
program uses `lbu` (and READ returns the byte zero-extended).

## U4 Computer organisation
My block works in the **memory step** of the instruction cycle: the screen is a device on the I/O
bus, so a store (`sw` to SCREEN_CHAR / SCREEN_CLEAR / SCREEN_CURSOR) or a load (`lw` from
SCREEN_CURSOR / SCREEN_READ) is what reaches it. The instructions that need it are
therefore `sw`, `sb` and `lw`, `lb`, `lbu` aimed at addresses 0x000204C0 and up. The other steps
(fetch, decode, execute) treat these like any other load or store.

## U5 Processors
A CISC processor could have a single instruction to print a string or copy a block to the screen
(like Mano's OUT instruction, or a string-move instruction), where RISC-V needs a loop of `sb`/`sw`.
A stack machine would push the character and call a "print" operation; the cursor would live in memory
or on the stack instead of in a device register. A GPU would own a frame buffer and many threads could
write cells in parallel, so clearing the whole screen would be one parallel operation; my CLEAR also
clears all 64 cells in one clock, but through a loop in the hardware description.
RC-V is RISC with memory-mapped I/O, so no special I/O instructions (INP, OUT) are needed.

## U6 Memory and I/O
The block is an I/O device in slot 19, registers at 0x000204C0 + 4*r (r = 0 CHAR, 1 CURSOR, 2 CLEAR,
3 READ, 15 reads 61, the package number). A write happens at the clock edge when sel and we are 1;
rdata always shows register ridx and does not wait for the clock. The address decoder (P31) and the I/O
bus (P33) set `sel` and `ridx` and pass `wdata`; the store-align block (P27) prepares the data and the read
select / load extend blocks (P32, P28) bring `rdata` back to the register file. CHAR writes a byte at the
cursor and advances (0x0A moves to the next row), READ returns the byte under the cursor.
It is programmed I/O: no interrupts and no DMA, because the screen is always ready.

## E1 Instruction trace: ORI
Example instruction: `ori t0, t1, 0x0F` with t1 = 0x30 (rs1 = x6, rd = x5).
Encoding: imm[11:0] = 000000001111, rs1 = 00110, funct3 = 110, rd = 00101, opcode = 0010011 -> 0x00F36293.

| Step | Block | Main signals |
|---|---|---|
| Fetch | P14 PC, P30 ROM | PC = address of the instruction, instr = 0x00F36293 |
| Fetch | P03 (+4) | PC + 4 is prepared |
| Decode | P17 fields | opcode 0010011, rd = 5, funct3 = 110, rs1 = 6, imm[11:0] = 0x00F |
| Decode | P21 class decoder, P22 hardwired (P23 control ROM, P24 select) | class OP-IMM, control word 0x5000: regwrite = 1, bsel_imm = 1, wbsel = 0 (ALU), immsel = 0 (I-type) |
| Decode | P18/P19 immediates, P20 select | immediate = 0x0000000F (sign-extended from 12 bits) |
| Decode | P11-P13 register file | rs1 value = 0x00000030 |
| Execute | P26 operand select | A = 0x30 (register), B = 0x0F (immediate, because bsel_imm = 1) |
| Execute | P10 ALU control, P01-P08 ALU | funct3 110 selects OR: 0x30 OR 0x0F = 0x0000003F |
| Execute | P09 branch compare, P02 target adder | not used (not a branch or jump) |
| Memory | P34 / P31 / P29 / P33 | no memory or I/O access (memread = memwrite = 0) |
| Write back | P25 write-back, P11/P12 register file | wbsel = 0 picks the ALU result, so x5 (t0) = 0x0000003F |
| Next PC | P16 next-PC logic, P15 | no branch or trap, so next PC = PC + 4 |

The control word and the block order come from the control-word table and the datapath diagram in
docs/ARCHITECTURE.md; the register values are worked out by hand for this example instruction.

## E2 Neighbour review
Review the pull requests of P60 (Parity generator) and P62 (Interrupt latency meter). Paste the links to your review
comments here.

- P60: https://github.com/campus-sutra/rc-v/pull/113/changes#r4599946855 (my review comment on p60.s: stack frame, parity register use, output format, and tests to add)
- P62: no hand-in available at the time of writing, will review once submitted

## E3 Where my block sits
My block is in the I/O layer (with a small component-level part inside: the cursor register and adders).
It is fed by the address decoder and I/O bus (P31, P33) with sel, we, re, ridx and wdata, and by the
store-align block (P27) for the data. Its output rdata is used by the read-select and load-extend blocks
(P32, P28) and then the write-back (P25), whenever a program reads CURSOR or READ; the test bench and the
checker also read the screen through dbg_addr and dbg_char.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 6).

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
