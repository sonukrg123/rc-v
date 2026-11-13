# P40 Illegal-instruction detector - dossier

## U1 Digital logic

The detector first compares the instruction's opcode (`instr[6:0]`) with the supported opcode values. It then checks `funct3` and, where the instruction format requires it, `funct7`. Each equality comparator outputs 1 when its two inputs match and 0 otherwise.

For a two-input equality comparator, the truth table is:

| A | B | A = B |
|---:|---:|---:|
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

For multi-bit fields, equality is true only when every corresponding bit matches. The valid-instruction conditions are combined with AND/OR logic. The final expression is `illegal = NOT(valid_instruction)`. No flip-flops are needed because this is combinational logic.

The important restrictions are: R-type `funct7` is 0, except ADD/SUB and SRL/SRA may also use `0x20`; OP-IMM shifts have restricted upper immediate bits; loads, stores, branches and JALR have defined `funct3` values; SYSTEM accepts ECALL, MRET and register-form CSR operations.

## U2 Digital components

The circuit uses a splitter to extract opcode, `funct3` and `funct7` from the 32-bit instruction. Comparators compare those fields with constants. AND gates combine an opcode match with the required function-field checks; OR gates combine the supported instruction classes; a final NOT produces `illegal`. There are no adders, multiplexers, registers or memories in this detector.

## U3 Data representation

Three example 32-bit test vectors are:

| Instruction word | Binary (grouped) | Unsigned decimal | Meaning / expected output |
|---|---|---:|---|
| `0x00000013` | `00000000 00000000 00000000 00010011` | 19 | ADDI/NOP encoding; legal, `illegal=0` |
| `0x00000000` | `00000000 00000000 00000000 00000000` | 0 | Unsupported instruction; illegal, `illegal=1` |
| `0xFFFFFFFF` | `11111111 11111111 11111111 11111111` | 4294967295 (signed: -1) | Unsupported instruction; illegal, `illegal=1` |

The instruction is a bit pattern, not an arithmetic quantity. Treating `0xFFFFFFFF` as signed -1 instead of unsigned 4294967295 must not change the bit comparisons. Sign extension matters when immediates are decoded elsewhere in the processor; it must not be confused with opcode or function-field decoding.

## U4 Computer organisation

The detector works during instruction decode. The instruction is fetched from instruction ROM, and its fields are decoded. P40 checks whether the opcode/function combination is in the RC-V supported subset. If it is illegal, the trap path reports an illegal-instruction exception (`mcause=2`) and the normal instruction must not execute. Legal instructions continue through the normal execute, memory and write-back stages.

## U5 Processors

A CISC processor may use more complex, variable-length instruction decoding and a larger set of instruction formats, so its legality checks can be more complicated. A stack machine would decode stack-oriented operations instead of the RISC-V register fields. A GPU also validates instruction encodings, but its decoder is designed for its own parallel execution model and instruction set. The principle is the same: reject encodings the processor does not implement.

## U6 Memory and I/O

P40 does not read or write data memory and does not directly perform I/O. It only examines the fetched instruction word. For an SW to a memory-mapped terminal register, the store datapath and bus/address-decoding blocks perform the transfer: P27 aligns store data, P34 arbitrates the bus, P31 decodes the address, P33 selects the I/O bus and the terminal device receives the value.

## E1 Instruction trace: SW to the terminal

A trace from the P40 program's use of `rcv_putc` shows the store at PC `0x00000404`:

- Instruction word: `0x00A2A023`, which is `sw x10, 0(x5)` (`sw a0, 0(t0)`).
- Opcode: `0x23` (STORE); `funct3=010` (SW).
- `rs1=x5` (`t0`) contains `0x00020000`, the terminal TXDATA address.
- `rs2=x10` (`a0`) contains `0x00000069`, the character `i`.
- S-type immediate is 0, so the ALU address is `0x00020000 + 0 = 0x00020000`.
- `memwrite=1`, `memread=0`, and the store data is `0x00000069`.
- P40 sees a supported STORE opcode and SW `funct3`, so `illegal=0`.

The path is: P14 PC and P30 instruction ROM fetch the word; P17 extracts fields; P40 checks legality; P21 classifies STORE; P22/P23 and P24 produce/check the control word; P18/P19/P20 form the S immediate; P11/P12/P13 read the register operands; P26 selects operands; P10 controls the ALU and P01-P08 calculate the address; P27 aligns the store data; P34 arbitrates the bus; P31 decodes `0x00020000` as terminal I/O; P33 selects the I/O bus; P41 receives the write at TXDATA. P03/P15 update the PC for the next instruction.

The simulator trace around this instruction records `x5=0x00020000` immediately before the store and `x10=0x00000069` as the character value. The store instruction itself appears at PC `0x00000404`.

## E2 Neighbour review

P39 (Trap controller): the key review points are that synchronous exceptions must save the faulting PC in `mepc`, record the correct cause in `mcause`, select `mtvec`, and coordinate the return path. A useful test is an illegal instruction followed by a valid instruction, verifying that the exception is taken and execution resumes at the intended address.

P37 (Control and status registers): the key review points are correct CSR address decoding, read/write enables, reset values, and preservation of unrelated CSR bits during updates. Useful tests should cover reads and writes of `mtvec`, `mepc`, `mcause`, `mstatus` and `mscratch`.

Review comments have not been posted to the classmates' pull requests from this offline working copy, so there are no genuine comment URLs to paste here. Before submission, open the P39 and P37 pull requests, leave one constructive comment on each, and replace this note with the two actual review-comment links.

## E3 Where my block sits

P40 is a combinational control/decode block built from gates and comparators. Its input is the 32-bit instruction from instruction ROM; it examines opcode, `funct3` and `funct7`. Its `illegal` output is consumed by the trap-control path (P39), which works with the CSR block (P37) to record and handle the exception.

## E4 Syllabus map

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
