# P01 ALU Adder/Subtractor — Dossier

## U1 Digital Logic

I used the full adder as the basic building block. It has three inputs: A, B and Cin, and two outputs: S (sum) and Cout (carry out).

| A | B | Cin | S | Cout |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 |
| 0 | 1 | 1 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 1 | 0 | 1 |
| 1 | 1 | 0 | 0 | 1 |
| 1 | 1 | 1 | 1 | 1 |

The sum is 1 when an odd number of inputs are 1:

**S = A XOR B XOR Cin**

The carry output is 1 when at least two inputs are 1. Its simplified Boolean expression is:

**Cout = (A AND B) OR ((A XOR B) AND Cin)**

This expression reuses the XOR result needed for the sum.

Each full adder uses 2 XOR gates, 2 AND gates and 1 OR gate. The complete 8-bit circuit also uses 8 XOR gates to calculate B XOR sub and 1 XOR gate to calculate the overflow flag:

**v = C7 XOR C8**

The circuit is purely combinational, so it does not require flip-flops or other sequential storage elements.

## U2 Digital Components

I did not use any ready-made adder, multiplexer, decoder, register or memory component. The circuit is constructed using AND, OR and XOR gates, together with splitters for the 8-bit input and output buses.

The circuit works as follows:

1. Eight XOR gates calculate B XOR sub, one for each bit.
2. Eight full adders are connected in a ripple-carry arrangement.
3. The carry output of each bit is connected to the carry input of the next bit.
4. The initial carry input is C0 = sub.
5. The final carry output is C8, which becomes the carry output c.
6. The signed overflow output is calculated as v = C7 XOR C8.

When sub = 0, the circuit performs addition:

**a + b**

When sub = 1, it performs subtraction using two's complement:

**a + NOT(b) + 1**

The initial carry input sub provides the required +1 during subtraction.

## U3 Data Representation

The Digital circuit uses 8-bit inputs and outputs, while the Verilog implementation uses 32-bit values.

| Operation | a | b | B used | y | c | v |
|---|---|---|---|---|---|---|
| 127 + 1 | 0x7F | 0x01 | 0x01 | 0x80 | 0 | 1 |
| 0 - 1 | 0x00 | 0x01 | 0xFE | 0xFF | 0 | 0 |
| 5 - 5 | 0x05 | 0x05 | 0xFA | 0x00 | 1 | 0 |

**Example 1: 127 + 1**

In binary:

0x7F + 0x01 = 0x80

The unsigned result is 128, which fits in 8 bits, so c = 0. However, in signed 8-bit representation, 0x80 represents -128. Since the actual answer is +128, which cannot be represented in signed 8-bit form, signed overflow occurs: v = 1.

**Example 2: 0 - 1**

Subtraction is performed as:

0x00 + 0xFE + 1 = 0xFF

The result 0xFF represents -1 in signed 8-bit two's complement. There is no signed overflow, so v = 0. The carry output is 0, indicating that an unsigned borrow occurred.

**Example 3: 5 - 5**

Subtraction is performed as:

0x05 + 0xFA + 1 = 0x100

The lower 8 bits give y = 0x00, and the carry output is 1. In subtraction, c = 1 means no unsigned borrow occurred. There is no signed overflow, so v = 0.

Some common mistakes include forgetting the +1 during subtraction, confusing unsigned carry with signed overflow, and incorrectly extending signed values.

When widening an 8-bit signed value to 32 bits, sign extension must be used by copying the most significant bit into the new upper bits.

The most negative 8-bit value is -128. For example, -128 - 1 produces 127 in 8-bit arithmetic with signed overflow. Similarly, +128 cannot be represented in signed 8-bit form.

In my RISC-V assembly program, signed overflow is detected using the sign-bit rule rather than using a wider register.

## U4 Computer Organisation

RC-V is a single-cycle 32-bit RISC-V processor. Each instruction passes through fetch, decode, execute, memory, write-back and next-PC selection within one clock cycle.

My adder/subtractor is part of the arithmetic datapath used by the ALU.

The relevant datapath connections are:

- P26 selects the ALU operands from the register file or immediate path.
- P10 generates the ALU control signals.
- P01 and the related arithmetic and logic components P04-P07 contribute to the complete ALU P08.
- P08 produces the ALU result.

The adder/subtractor is useful for arithmetic operations such as ADD, SUB and ADDI. It can also calculate effective memory addresses for LW and SW by adding a base register value and an offset.

The processor uses a separate branch comparison block, P09, for conditional branch comparisons. The branch-target address is calculated by P02. Therefore, these functions should not be confused with the P01 adder/subtractor.

RC-V supports both hardwired and microprogrammed control:

- P22 generates control signals using logic gates.
- P23 obtains the control word from control memory.
- P24 selects between the two control sources and checks whether their outputs match.

The processor can use either control implementation.

## U5 Processors

**CISC processor (example: x86)**

CISC processors can support instructions with memory operands, unlike the load-store approach used by RISC-V. Arithmetic instructions such as ADD and SUB update status flags, including the carry flag (CF) and overflow flag (OF). Conditional instructions can use these flags.

RISC-V does not have a general-purpose arithmetic flags register. Its arithmetic results do not automatically update carry and overflow flags. Programs can calculate conditions such as signed overflow using software, as I have done in my p01.s program.

**Mano's Basic Computer**

Mano's Basic Computer uses an accumulator (AC). Its ADD instruction adds a memory word to AC, and the carry is stored in the E flip-flop.

Subtraction can be performed using complement and addition, which is related to the two's-complement method used in my circuit:

**A - B = A + NOT(B) + 1**

**Stack machine**

A stack machine uses a stack to supply operands. An ADD instruction pops two values, adds them and pushes the result back onto the stack. The arithmetic operation is similar, but the operands are obtained from the stack instead of explicitly named registers.

**GPU**

GPUs execute many operations in parallel using architectures such as SIMD and SIMT. Arithmetic units perform similar operations on multiple data elements, allowing parallel processing of vectors and large datasets.

## U6 Memory and I/O

The P01 adder/subtractor does not access memory or I/O directly. It only performs arithmetic and produces a result.

In RC-V, the ALU can calculate an effective address for load and store instructions. The address is then sent through the bus arbiter and address decoder to the appropriate memory or I/O device.

The RC-V memory map includes:

- ROM for program instructions, constants and initial data.
- RAM for data and stack storage.
- Memory-mapped I/O for device registers.

The processor accesses memory-mapped devices using ordinary load and store operations. The terminal and keyboard are examples of I/O devices. Library routines such as rcv_puts and rcv_read_dec provide convenient program-level interfaces to I/O.

The architecture also includes a DMA controller. DMA can transfer data between memory and devices while stealing processor cycles, causing the processor to wait during those cycles.

Thus, the adder/subtractor is part of the processing datapath, while memory and I/O transfers are handled by the surrounding bus and memory system.

## E1 Instruction Trace: LUI

Example instruction:

**lui x5, 0x12345**

Machine instruction:

**0x123452B7**

The instruction contains:
- Opcode = 0110111 (0x37)
- Destination register rd = x5
- Immediate field = 0x12345
- U-type immediate = 0x12345000

According to the RC-V architecture, the LUI control word is **0x5830**.

| Block | What happens | Expected value |
|---|---|---|
| Program counter | Supplies the address of the instruction | PC = actual trace value |
| Instruction memory | Supplies the instruction word | instr = 0x123452B7 |
| Decoder/control | Identifies the LUI opcode | Control word = 0x5830 |
| Immediate generator | Generates the U-type immediate | imm = 0x12345000 |
| Register file | Selects the destination register | rd = x5 |
| ALU operand selection | Selects zero for input A and the immediate for input B | a_zero = 1, bsel_imm = 1 |
| ALU | Produces the immediate value by adding it to zero | result = 0x12345000 |
| Write-back | Selects the ALU result and writes it to rd | wbsel = 0, regwrite = 1 |
| Register file | Stores the result in x5 | x5 = 0x12345000 |
| PC adder | Calculates the next sequential instruction address | PC + 4 |

The LUI control word also selects U-type immediate generation (immsel = 3). Memory read, memory write and branch controls are disabled.

**Note:** The values shown are the expected signal values based on the RC-V architecture for the LUI instruction.
## E2 Neighbour Review

**P10 – ALU Control**

Review comment link: Pending submission of the pull request.

**P02 – Branch-target Adder (Carry Look-Ahead)**

Review comment link: Pending submission of the pull request.
## E3 Where My Block Sits

My block belongs to the arithmetic component layer of the processor datapath.

It forms part of the complete ALU P08, together with the related components P04-P07. Its operands are selected through P26, and the ALU operation is controlled by P10.

The arithmetic result is used by the datapath for operations such as arithmetic instructions and effective-address calculation. The result can be sent to the write-back unit P25 or used in the memory-address path.

Branch comparison is handled separately by P09, while branch-target calculation is handled by P02.

Therefore, P01 contributes to the execution stage of the RC-V processor and works with the other datapath components rather than operating as a complete processor by itself.

## E4 Syllabus Map

The following checklist identifies the syllabus topics connected to this project and its architecture.

- [x] Logic gates, Boolean algebra and K-maps
- [x] Combinational circuits (adders, decoders, encoders and multiplexers)
- [x] Flip-flops, registers and counters (conceptual comparison with sequential circuits)
- [x] Memory (RAM and ROM)
- [x] Number systems, complements and signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired and microprogrammed control
- [x] Interrupts and the interrupt cycle
- [x] Pipelining (comparison with the single-cycle processor)
- [x] Register organisation, stack and addressing modes
- [x] RISC vs CISC, multicore and GPU
- [ ] Memory hierarchy and cache
- [x] I/O interface, programmed and interrupt-driven I/O, DMA