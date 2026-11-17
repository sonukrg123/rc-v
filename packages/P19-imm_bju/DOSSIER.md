# P19 Immediate generator B/J/U - dossier

## U1 Digital logic
My block contains no logic gates at all. Every output bit is either a copy of an input bit, a constant 0, or a copy of the sign bit, so the "truth table" is a wiring table, and each output bit is the identity function of one input bit:

| output bit | source | Boolean expression |
|---|---|---|
| imm_b[0] | constant | 0 |
| imm_b[4:1] | instr[11:8] | imm_b[k] = instr[k+7] |
| imm_b[10:5] | instr[30:25] | imm_b[k] = instr[k+20] |
| imm_b[11] | instr[7] | imm_b[11] = instr[7] |
| imm_b[31:12] | instr[31] | imm_b[k] = instr[31] |
| imm_j[0] | constant | 0 |
| imm_j[10:1] | instr[30:21] | imm_j[k] = instr[k+20] |
| imm_j[11] | instr[20] | imm_j[11] = instr[20] |
| imm_j[19:12] | instr[19:12] | imm_j[k] = instr[k] |
| imm_j[31:20] | instr[31] | imm_j[k] = instr[31] |
| imm_u[11:0] | constant | 0 |
| imm_u[31:12] | instr[31:12] | imm_u[k] = instr[k] |

Gates or flip-flops needed: none. The block is purely combinational (no memory), and only Splitters, Ground and a Const are used.

## U2 Digital components
- **Splitters**: one 32-bit to (7,1,4,8,1,4,6,1) splitter cuts the instruction into the pieces that B, J and U need. Three merging splitters (many inputs, one 32-bit output) rebuild imm_b, imm_j and imm_u.
- **Ground** supplies the constant 0 in bit 0 of imm_b and imm_j; a **12-bit Const 0** fills the low bits of imm_u.
- The sign bit instr[31] is wired to every input that must be sign-extended: 20 inputs for imm_b (bit 12 and the 19 extension bits) and 12 for imm_j (bit 20 and the 11 extension bits).
- No adders, multiplexers, decoders, registers or memory. Choosing between B, J and U is done outside this block, by the immediate selector (P20).

## U3 Data representation
Three test vectors from my test file:

| instr (hex) | instr (binary) | imm_b | imm_j | imm_u |
|---|---|---|---|---|
| 0xFFFFFFFF | all 32 bits 1 | 0xFFFFFFFE = -2 | 0xFFFFFFFE = -2 | 0xFFFFF000 = -4096 |
| 0x80000000 | 1000 0000 ... 0000 | 0xFFFFF000 = -4096 | 0xFFF00000 = -1048576 | 0x80000000 = -2147483648 |
| 0x123450B7 | 0001 0010 0011 0100 0101 0000 1011 0111 | 0x00000920 = +2336 | 0x00045922 = +284962 | 0x12345000 = +305418240 |

Explanation of the third row: bits 30:25 = 001001 and bit 7 = 1 and bits 11:8 = 0000. So imm_b = bit 11 (0x800) + bit 8 (0x100) + bit 5 (0x020) = 0x920, and bit 0 is 0 because branch targets are even.

Where things can go wrong:
- **Sign extension**: the sign is always instr[31] for all three formats (for U it ends up as bit 31 of the result). Extending from any other bit, e.g. instr[7] or instr[20], gives a wrong sign for every negative offset.
- **Bit order**: the B and J fields are scrambled, so one swapped bit (e.g. instr[7] and instr[20] for bit 11) gives a wrong offset that only some test vectors reveal.
- **Bit 0**: it must be forced to 0, not taken from the instruction.
- **Overflow**: the immediate itself cannot overflow (the widths are fixed), but adding it to the PC later can wrap around.
- **imm_u** is not shifted by an adder. It is the upper 20 bits followed by 12 zeros, and it is read as a signed 32-bit value.

## U4 Computer organisation
The block works in the **decode** step of the instruction cycle, in the same clock cycle as the register read. It is combinational, so its outputs are ready as soon as `instr` is stable, and the execute step uses the selected value.

Instructions that need it:
- **B-type** (BEQ, BNE, BLT, BGE, BLTU, BGEU): imm_b is the branch offset added to the PC.
- **J-type** (JAL): imm_j is the jump offset added to the PC.
- **U-type** (LUI, AUIPC): imm_u is the value loaded or added to the PC.

## U5 Processors
- **CISC**: instruction length is variable and displacement or immediate fields are placed after the opcode in separate bytes. They are read in order, so no bit shuffling is needed, but a more complex decoder is needed to find where each field starts.
- **Stack machine**: most instructions have no operand fields at all because their operands are on the stack. Only push-immediate or jump instructions carry a constant, and it is stored in one contiguous field, so there is nothing to put back together.
- **GPU**: it has many simple cores that run the same instruction on different data. The immediate is decoded once per instruction and shared across the lanes.
- RISC-V keeps the register fields at fixed positions across formats, which makes the register file read fast. As a result, the immediate bits get moved around, and that is the job of this block. (I have not read docs/ARCHITECTURE.md; this comparison is from general knowledge.)

## U6 Memory and I/O
My block does not touch memory or I/O. It does not access memory or an I/O device by itself. It only produces values that indirectly affect where the program counter points next, which changes which instruction address is fetched next, and a branch or jump target is a memory address in the instruction memory. The memory access itself is done by the program counter / instruction memory, and loads and stores use the I/S immediate from P18 plus the ALU. Data reaches the block only through the `instr` input, which comes from instruction memory.

## E1 Instruction trace: XORI
Example instruction: `xori x5, x6, 0x0FF`, encoded as **0x0FF34293** (imm[11:0] = 0x0FF, rs1 = 6, funct3 = 100, rd = 5, opcode = 0010011). Assume x6 = 0x0000F0F0 and PC = 0x100.

| Step | Block | What happens | Signal values |
|---|---|---|---|
| 1 Fetch | PC and instruction memory | PC addresses the memory and returns the instruction | PC = 0x00000100, instr = 0x0FF34293 |
| 2 Decode | Control unit | opcode 0010011 and funct3 100 are recognised as an I-type ALU operation (XOR) | ALU op = XOR, ALU source B = immediate, reg write = 1, mem write = 0, branch = 0 |
| 2 Decode | Register file | reads rs1 = x6 | rs1 data = 0x0000F0F0 |
| 2 Decode | Immediate generator I/S (P18) and selector (P20) | the I-immediate (instr[31:20]) is sign-extended and chosen | imm = 0x000000FF |
| 3 Execute | ALU | XOR of register value and immediate | 0x0000F0F0 XOR 0x000000FF = 0x0000F00F |
| 4 Memory | Data memory | not used | no access |
| 5 Write-back | Register file | ALU result is written to rd = x5 | x5 = 0x0000F00F |
| next PC | PC adder | PC + 4 | 0x00000104 |

My block (P19) also computes imm_b, imm_j and imm_u for this instruction, but the selector does not pick them, so they are unused in this trace.

Note: this table follows the standard RISC-V single-cycle datapath. I have not seen the simulator's `--trace` output or docs/ARCHITECTURE.md, so compare the block names and signal values with your own `--trace` run and adjust them if the RC-V names differ.

## E2 Neighbour review
Review the pull requests of P18 (Immediate generator I/S) and P20 (Immediate selector).

- P18 review comments:Not available. P18 has not submitted a pull request yet
- P20 review comments: Not available. P20 has not submitted a pull request yet

## E3 Where my block sits
My block sits in the **datapath** layer, in the decode part. It is fed by the instruction memory (fetch) through the 32-bit instruction word. Its three outputs go to the immediate selector (P20), which picks one immediate for the ALU or the PC adder.

## E4 Syllabus map

- [ ] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA