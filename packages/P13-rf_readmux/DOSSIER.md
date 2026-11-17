# P13 Register-file read port - dossier

## U1 Digital logic

My block is purely combinational: no flip-flops, only NOT, AND and OR gates.

The register number `ra` (2 bits in the Digital circuit) is decoded into four select lines:

| ra1 | ra0 | sel0 | sel1 | sel2 | sel3 |
|-----|-----|------|------|------|------|
| 0   | 0   | 1    | 0    | 0    | 0    |
| 0   | 1   | 0    | 1    | 0    | 0    |
| 1   | 0   | 0    | 0    | 1    | 0    |
| 1   | 1   | 0    | 0    | 0    | 1    |

Simplified expressions: sel0 = ra1' . ra0', sel1 = ra1' . ra0, sel2 = ra1 . ra0', sel3 = ra1 . ra0.

Each output bit is: rd[k] = (sel0 . r0[k]) + (sel1 . r1[k]) + (sel2 . r2[k]) + (sel3 . r3[k]), which is a 4-to-1 multiplexer built from AND and OR gates.

## U2 Digital components

The Digital circuit uses a splitter to cut the 16-bit `q_flat` into four 4-bit registers, a decoder made of NOT and AND gates that turns `ra` into four select lines, four groups of AND gates that gate each register with its select line, and OR gates that combine them into the 4-bit output `rd`. In the Verilog version the same idea is a 32-to-1 multiplexer of 32-bit words: `q_flat` holds 32 registers of 32 bits and `ra` (5 bits) selects one.

## U3 Data representation

Assuming register 0 is the lowest 4 bits of `q_flat`, take `q_flat = 0xDCBA` (registers r0 = A, r1 = B, r2 = C, r3 = D):

- ra = 00 gives rd = 1010 = 0xA = 10 unsigned, -6 signed (4-bit)
- ra = 01 gives rd = 1011 = 0xB = 11 unsigned, -5 signed
- ra = 11 gives rd = 1101 = 0xD = 13 unsigned, -3 signed

The block only copies bits, so it cannot overflow. Problems appear after it: a narrow signed value must be sign-extended (copy the top bit), not zero-extended, when it is used in a wider datapath. Another mistake is mixing up which register sits at which bit positions of `q_flat`.

## U4 Computer organisation

The block works in the decode step (register read) of the instruction cycle, when the register numbers rs1 and rs2 from the instruction are used to fetch the operand values. Instructions that need it are those that read registers: R-type (add, sub, and, or ...), I-type (addi, lw, jalr), S-type (sw, which reads two registers) and B-type (beq, bne ...). Instructions like lui and jal do not need it.

## U5 Processors

A CISC processor can take an operand straight from memory in one instruction and often has fewer registers, so its register read is mixed with address calculation and microcode. A stack machine has no register numbers at all: operands are popped from the top of the stack, so there is no read port like mine. A GPU has a very large register file with many read ports (banks) so that many threads can read at the same time. In the Mano basic computer there is mainly one accumulator register, so no register selection is needed. RISC-V keeps it simple: two register numbers in the instruction and two read ports.

## U6 Memory and I/O

The block itself does not access memory or I/O. It only reads the register file. For a load, it supplies the base address register rs1; the ALU adds the immediate; the data memory block reads the word; and the value returns to the register file through the write-back path. I/O is memory-mapped: the library reads and writes the UART and keyboard addresses with ordinary `lw` and `sw`, so the same register read supplies those addresses too.

## E1 Instruction trace: LW

Example instruction `lw rd, imm(rs1)`, block by block:

1. PC (P14) gives the address and the PC incrementer (P03) prepares PC + 4.
2. Instruction memory returns the 32-bit instruction.
3. The instruction field splitter (P17) extracts rs1, rd and the immediate bits.
4. The register-file read port (P13, my block) uses ra = rs1 and outputs the value of rs1.
5. The immediate generator (P18) and immediate selector (P20) produce the sign-extended offset.
6. The ALU adder (P01) computes address = rs1 value + offset.
7. Data memory reads the word at that address.
8. The result selector (P08) chooses the memory data for write-back.
9. The write decoder (P11) and register storage (P12) write the value into register rd.

Main signal values depend on the program; replace this with real values from the simulator's `--trace` output if you can run it.

## E2 Neighbour review

(Write the links to your review comments on the P12 and P14 pull requests here.)

## E3 Where my block sits

My block is in the datapath layer. It is fed by the register storage (P12), which provides `q_flat`, and by the instruction field splitter (P17), which provides the register number. Its output goes to the ALU (P01) and the immediate and result selectors, and for stores it also provides the data to write to memory.

## E4 Syllabus map

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [ ] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
