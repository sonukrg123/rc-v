# P30 Boot ROM - dossier

## U1 Digital logic
A ROM is a combinational lookup table: the 4 address bits select one of 16 stored words. Every output bit is therefore an ordinary Boolean function of the address. I looked at data bit 6 (D6), which is the simplest non-constant one. Let A B C D be addr[3] (MSB) down to addr[0].

| addr | A B C D | word | D6 |
|---|---|---|---|
| 0 | 0000 | 0x000002B7 | 0 |
| 1 | 0001 | 0x46028293 | 0 |
| 2 | 0010 | 0x00010337 | 0 |
| 3 | 0011 | 0x00030313 | 0 |
| 4 | 0100 | 0x000103B7 | 0 |
| 5 | 0101 | 0x00038393 | 0 |
| 6 | 0110 | 0x00737C63 | **1** |
| 7 | 0111 | 0x0002AE03 | 0 |
| 8 | 1000 | 0x01C32023 | 0 |
| 9 | 1001 | 0x00428293 | 0 |
| 10 | 1010 | 0x00430313 | 0 |
| 11 | 1011 | 0xFEDFF06F | **1** |
| 12 | 1100 | 0x00014137 | 0 |
| 13 | 1101 | 0x00010113 | 0 |
| 14 | 1110 | 0x000002B7 | 0 |
| 15 | 1111 | 0x05828293 | 0 |

D6 = 1 only for minterms 6 and 11. They share no neighbouring cell on the K-map, so no grouping is possible and the simplified form is the sum of the two minterms:

**D6 = ¬A·B·C·¬D + A·¬B·C·D**

That needs 2 AND gates (4 inputs each), 4 NOT gates and 1 OR gate. Bits 0 and 1 are constant 1 for all 16 words, because every 32-bit RISC-V instruction ends in `11`. In my circuit I did not build these gates. A single ROM part does the whole job (a ROM is internally an address decoder plus an OR matrix).

## U2 Digital components
The circuit uses only three kinds of parts:
- **ROM** (4 address bits, 32 data bits, 16 words) holding the first 16 words of the boot program.
- **Const** with value 1, wired to the ROM's select input so the ROM is always enabled.
- **Input pin `addr`** (4 bits) wired to the ROM address input, and the ROM data output wired to **Output pin `data`** (32 bits).

Inside the ROM part there is a 4-to-16 decoder that picks one word line, and memory cells that hold the bits. There are no adders, registers or flip-flops, because the ROM only reads.

## U3 Data representation
Three test vectors (the same words the public test checks):

| addr | hex | binary | unsigned decimal | meaning |
|---|---|---|---|---|
| 0 | 0x000002B7 | 0000 0000 0000 0000 0000 0010 1011 0111 | 695 | `lui t0, 0` |
| 3 | 0x00030313 | 0000 0000 0000 0011 0000 0011 0001 0011 | 197395 | `addi t1, t1, 0` |
| 11 | 0xFEDFF06F | 1111 1110 1101 1111 1111 0000 0110 1111 | 4276088943 (signed: -18878353) | `jal x0, -20` (the `j rcv_copy` loop jump) |

Word 11 shows where signs matter. Its top bit is 1, so as a signed 32-bit number it is negative. It encodes a jump backwards by 20 bytes. The J-format offset is spread over scattered bits and then sign-extended, so a forgotten sign extension would turn -20 into a huge forward jump. Overflow risks in the circuit: writing a word as a signed decimal in the Digital testcase can overflow (words with bit 31 set must be typed as unsigned, or in hex), and a ROM `Data` field with the wrong number of hex digits silently gives wrong words. The ROM only has 16 words for a 4-bit address, so an address of 16 or more would wrap around.

## U4 Computer organisation
The ROM works in the **fetch** step: the PC (P14) sends the address and the ROM returns the instruction word for the decoder (P17, P21, immediates). Every instruction needs it, because every instruction is fetched from here. It also works in the **memory** step through its second read port: loads (`lw`, `lbu`) from addresses below 0x10000 read constants from `.rodata`. My P30 program uses this when it reads the string-pointer table and the strings. In the first cycles the processor runs the ROM's boot code (crt0), which copies initial data, sets the stack and the trap vector, and calls `main`.

## U5 Processors
- **CISC:** instructions have variable length (1 to 15 bytes on x86) and may read memory directly in the middle of an operation. The ROM would have to return a variable number of bytes per fetch, often through an instruction queue. Instruction decoding would use a large microcode ROM. RC-V instead fetches exactly 32 bits every cycle.
- **Stack machine:** most instructions have no operands (`add` pops two values and pushes the sum), so the code is much denser. The code ROM would still be read the same way, but a hardware stack (like P63) replaces the register file.
- **GPU:** many threads (lanes) run the same instruction on different data. One instruction fetch is shared by all lanes, so the instruction memory is read once per group and not once per thread, and there is a large data memory next to it.

This follows the RISC-V vs Mano comparison in docs/ARCHITECTURE.md: RC-V uses 32-bit fixed instructions and a load-store design, while Mano's computer uses 16-bit instructions and memory-reference instructions.

## U6 Memory and I/O
The boot ROM occupies addresses 0x0000_0000 to 0x0000_FFFF (64 KB) in the memory map. It takes part in memory accesses only as a read-only device. The address decoder (P31) decides when an address belongs to the ROM, and the read select block (P32) puts the ROM data on the load path, which P28 sign- or zero-extends before write-back. Writes to ROM addresses are ignored. It is not an I/O device: the terminal, keyboard and timers are in the 0x0002_0000 I/O area and are reached through the I/O bus (P33), never through the ROM.

## E1 Instruction trace: XOR
I ran `xor t0, t1, t2` in the simulator (`python -m rcv.progrun 30 xor.s --trace`) with t1 = 0x00000F0F and t2 = 0x000000FF. The trace line is:

`55  00000240  007342b3  x5=0x00000ff0`

The instruction word 0x007342B3 is `xor x5, x6, x7`. Its trace through the processor:

| Step | Block | Signal values |
|---|---|---|
| Fetch | PC (P14) to boot ROM (P30) | PC = 0x240, ROM returns 0x007342B3 |
| Decode | Fields (P17) | opcode 0110011, rd = 5, funct3 = 100, rs1 = 6, rs2 = 7, funct7 = 0000000 |
| Decode | Class decoder (P21) and control (P22 / P23, chosen by P24) | class OP, control word 0x4000: regwrite = 1, bsel_imm = 0, memread/memwrite = 0, wbsel = ALU |
| Decode | Register file (P11, P12, P13) | rs1 = x6 = 0x00000F0F, rs2 = x7 = 0x000000FF |
| Execute | Operand select (P26) | A = 0x00000F0F, B = 0x000000FF (the immediate is not used) |
| Execute | ALU control (P10) and ALU (P08, XOR unit) | XOR: 0x0F0F ^ 0x00FF = 0x00000FF0 |
| Memory | none | memread = memwrite = 0, so the memory path is idle |
| Write-back | Write-back mux (P25) and register file | wbsel = ALU, x5 ← 0x00000FF0 |
| Next PC | PC+4 (P03), next-PC logic (P15, P16) | PC = 0x244 (not a branch or jump) |

## E2 Neighbour review
I reviewed P29 (Data memory) and P31 (Address decoder (memory map)).
- P29: <paste link to your review comment here>
- P31: <paste link to your review comment here>

## E3 Where my block sits
It sits in the **memory** layer of the computer. The PC (P14) feeds its instruction address, and the ALU address, through the bus arbiter (P34) and the address decoder (P31), feeds its data address. Its output goes to the instruction decoders (P17, P21, P18-P19) for fetch, and to the read select block (P32) and load-extend (P28) for constants read by loads.

## E4 Syllabus map
- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [x] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
