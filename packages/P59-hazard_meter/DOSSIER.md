# P59 Pipeline hazard meter - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
- The meter finds instructions that read the register written by the instruction just before them. The main signal is `hit`.
- Source match (`eq1` = rs1 equals prev_rd, `eq2` = rs2 equals prev_rd):

| uses_rs1 | eq1 | uses_rs2 | eq2 | match |
|---|---|---|---|---|
| 0 | x | 0 | x | 0 |
| 1 | 1 | x | x | 1 |
| x | x | 1 | 1 | 1 |
| 1 | 0 | 1 | 0 | 0 |

- match = (uses_rs1 AND eq1) OR (uses_rs2 AND eq2)
- hit = commit AND prev_we AND nz AND match (`nz` means prev_rd is not 0, so writes to x0 are ignored).
- lu_hit = hit AND prev_load.
- Counter state table (`inc` is `hit` for raw and `lu_hit` for loaduse):

| rst | inc | next count |
|---|---|---|
| 1 | x | 0 |
| 0 | 0 | count (hold) |
| 0 | 1 | count + 1 |

- The circuit uses AND, OR and NOT gates and D flip-flops.

## U2 Digital components
- D flip-flops, each with a multiplexer that keeps the old value unless `commit` is 1, store prev_rd (5 bits), prev_we and prev_load (1 bit each).
- Three 5-bit comparators: rs1 and rs2 against prev_rd, and prev_rd > 0.
- AND and OR gates combine the comparator outputs with `uses_rs1`, `uses_rs2`, `prev_we` and `commit` to make `hit` and `lu_hit`.
- Two 8-bit counters, each with a flip-flop, an Add (+1), a multiplexer that forces 0 on `rst` and a multiplexer that holds the value unless `hit` (or `lu_hit`) is 1.
- Data flow: previous rd is stored, compared with rs1 and rs2, combined into `hit`, which enables the raw counter; `hit` AND `prev_load` enables the loaduse counter.

## U3 Data representation
- Register numbers are unsigned 5-bit values from 0 to 31.

| Case | Binary | Hex | Decimal | Result |
|---|---|---|---|---|
| prev_rd = rs1 = x18 | 10010 | 0x12 | 18 | match, raw increases |
| prev_rd = rs1 = x31 | 11111 | 0x1F | 31 | match, raw increases |
| prev_rd = rs1 = x0 | 00000 | 0x00 | 0 | no hazard, x0 never holds a result |

- If the check prev_rd > 0 were signed, registers 16 to 31 (top bit set) would look negative and be ignored, so it must be unsigned.
- The 8-bit counters in the Digital circuit wrap from 255 to 0 (overflow). The Verilog counters are 32 bits wide.

## U4 Computer organisation
- The meter works at the end of the instruction cycle. It uses the rs1, rs2 and rd fields found in decode and watches each instruction as it commits (write-back).
- It compares the sources with the previous instruction's destination. A match adds 1 to RAW1, and if the previous instruction was a load it also adds 1 to LOADUSE.
- Instructions that read registers need it: R-type, I-type, loads, stores, branches and jalr.
- A load followed by an instruction that uses its result needs a stall in a pipeline, because loaded data arrives later than an ALU result.

## U5 Processors
- CISC: one instruction can do memory and ALU work in several microcode steps, so dependencies are hidden inside the instruction and harder to detect from fields.
- A stack machine has implicit operands, so there are no register names to compare. Dependencies follow stack order.
- A GPU hides delays by switching between many threads instead of stalling for one thread's hazard.
- RC-V has fixed 32-bit instructions with explicit register fields, so my meter can find hazards by comparing three 5-bit fields.

## U6 Memory and I/O
- Memory-mapped I/O device, slot 17 at 0x00020440. The CPU uses ordinary loads and stores, and `sel`, `we`, `re` and `ridx` pick the register.

| Offset | ridx | Register | Access |
|---|---|---|---|
| 0 | 0 | LOADUSE count | read |
| 4 | 1 | RAW1 count | read |
| 8 | 2 | CLEAR | write (resets both counters) |
| 60 | 15 | package number | read, returns 59 |

- My program clears the meter with `sw zero, 8(a5)`, runs a loop, then reads the counts with `lw a1, 0(a5)` and `lw a2, 4(a5)`.

## E1 Instruction trace: SLTIU
Example: `sltiu t0, a0, 10` = 0x00A53293, with a0 = 5 (hand-calculated).

| Field | imm[11:0] | rs1 | funct3 | rd | opcode |
|---|---|---|---|---|---|
| Binary | 000000001010 | 01010 | 011 | 00101 | 0010011 |

- PC and instruction memory give the instruction, and PC + 4 is computed.
- Decoder and control: opcode 0010011 (OP-IMM) and funct3 011 select SLTIU. rd = x5, rs1 = x10.
- Immediate generator: the 12-bit immediate 10 is sign-extended to 0x0000000A.
- Register file: reads a0 = 5.
- ALU: compares 5 < 10 as unsigned numbers, giving 1.
- Write-back: 1 is written to t0 (x5). No memory access, and PC becomes PC + 4.
- The immediate is sign-extended first and then compared as unsigned, so `sltiu t0, a0, -1` compares against 0xFFFFFFFF.

## E2 Neighbour review
Review the pull requests of P58 (Branch predictor (2-bit counters)) and P60 (Parity generator).

- P58 review: The 2-bit counter state table in U1 is correct and the saturation explanation in U3 is clear. I suggested adding state 11 (0x3) to the U3 table, giving a register map in U6, removing the duplicate E4 heading, and adding a worked example of the counter updating after taken branches.
- P60 review: The U3 examples and the xori trace are correct, which I checked by hand. I suggested clarifying the XOR gate count in U1 (7 two-input XORs per byte would give 31, not 15), stating that lb sign-extends so lbu is the right choice, fixing a typo in E3, explaining the flip-flop tick in E4, and updating the line about the P59 pull request.

## E3 Where my block sits
- It is in the I/O layer: a device on the I/O bus beside the datapath, built from comparators, gates, adders, multiplexers and flip-flops.
- It is fed by the commit-stage signals (`instr`, `rd`, `rf_we`, `is_load`, `commit`) and by the bus signals for reads and writes. The program reads its output with `lw`.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 4).

- [x] Logic gates, Boolean algebra, K-maps (gates and Boolean expressions; no K-maps used)
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [x] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA (memory-mapped I/O interface)
