# P29 Data memory - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

<img width="512" height="420" alt="image" src="https://github.com/user-attachments/assets/c5453fc5-6bda-4811-9eff-48ad278ff618" />

The circuit uses:
- AND gates: To combine the write enable and decoded address signals.
- NOT gates: To generate the complemented address bits.
- 2-to-4 Decoder: To select one of the four memory locations.
- D Flip-Flops: Four 8-bit D flip-flops to store data in the four memory locations.
- Multiplexers: To select the stored data according to the address during reading.




## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

1. 2-to-4 Decoder: It takes the 2-bit address (addr) as input and selects one of the four memory locations for writing.

2. AND Gates: Four AND gates combine the decoder outputs with the write-enable signal (we). This ensures that only the selected memory location is enabled for writing.

3. Multiplexers: Four 8-bit multiplexers are connected to the storage units to select between the previous stored value and the new input data (wdata). Another 8-bit, 4-to-1 multiplexer selects one of the four stored words for reading.

4. D Flip-Flops: Four 8-bit D flip-flops store the data. Each flip-flop represents one memory word and updates its value on the active clock edge when writing is enabled.

How they are connected:
- The 2-bit address goes to the decoder, which identifies the memory location to be accessed.
- The decoder outputs are combined with we through AND gates to control writing.
- The input data (wdata) is sent to the appropriate storage unit through the write multiplexers.
- The D flip-flops store the 8-bit data using the clock (clk).
- Their outputs are connected to the 4-to-1 read multiplexer, which uses the address to select the required word.
- The selected data appears at the output (rdata).   
## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

The P29 Digital circuit is a 4-word × 8-bit RAM. Its test vectors use the format:

clk, we, addr, wdata, rdata

Here, we = 1 means write data, while we = 0 means read data. The address is 2 bits and the data is 8 bits.

Test Vector 1: Writing 236 to address 2

| Signal | Decimal |	Binary |	Hex |
|---|---|---|---|
| Address (addr) |	3 |	11 |	0x3 |
| Write enable (we) |	1 |	1 |	0x1 |
| Write data (wdata) |	128 |	10000000 |	0x80 |
| Read output (rdata) |	128 |	10000000 |	0x80 |

Explanation: The write-enable signal is 1, so the circuit writes 236 into memory location 2 on the active clock edge. The output is 236.

Test Vector 2: Reading from address 3

| Signal | Decimal | Binary |	Hex |
|---|---|---|---|
| Address (addr) |	3 | 11 |	0x3 |
| Write enable (we) |	0 |	0 |	0x0 |
| Write data (wdata) |	68 |	01000100 |	0x44 |
| Read output (rdata) |	126 |	01111110 |	0x7E |

Explanation: Since write-enable is 0, no new data is written. The circuit reads the previously stored value, 126, from memory location 3. The input value 68 is ignored.

Test Vector 3: Writing 128 to address 3

| Signal | 	Decimal |	Binary |	Hex |
|---|---|---|---|
| Address (addr) |	3 |	11 |	0x3 |
| Write enable (we) |	1 |	1 |	0x1 |
| Write data (wdata) |	128 |	10000000 |	0x80 |
| Read output (rdata) |	128 |	10000000 |	0x80 |

Explanation: The write-enable signal is 1, so the value 128 is stored at address 3 on the active clock edge.

1. Overflow: The memory stores only 8 bits per word, so it can represent unsigned values from 0 to 255. If a value larger than 255 is supplied, the extra bits may be lost when it is truncated to 8 bits.

2. Sign extension: The memory stores bit patterns and does not itself distinguish between signed and unsigned numbers. For example, 11101100 represents 236 unsigned, but −20 signed in 8-bit two's complement. When extending this value to 32 bits, the sign bit must be replicated for signed interpretation. Otherwise, the value may be interpreted incorrectly.

3. Signed and unsigned interpretation: The value 10000000 represents 128 unsigned but −128 signed. Incorrect interpretation can cause errors when the stored data is used in later arithmetic operations.
## U4 Computer organisation

My Data RAM block does its work during the memory stage of the instruction cycle. It is mainly used by load and store instructions. The lw instruction reads data from RAM, while the sw instruction writes data into RAM. The address and control signals select the memory location, and the data is either read or written.
## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

CISC processor: It supports complex instructions that can perform multiple operations, including memory access, within a single instruction.

Stack machine: It uses a stack to store operands. Data is accessed using operations such as PUSH and POP instead of mainly using general-purpose registers.

GPU: It uses many parallel processing units to handle multiple memory operations and large amounts of data simultaneously.

In RC-V (RISC-V), a load-store architecture is used. Only load and store instructions access memory, while arithmetic and logical instructions operate on registers. In comparison, Mano's Basic Computer uses memory-reference instructions such as AND, ADD, LDA and STA. RC-V also uses 32 general-purpose registers, whereas Mano uses an accumulator (AC) along with registers such as DR, AR and TR.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

My block is used for data memory access. The processor sends the memory address, control signals and write data to the RAM. During a read operation, RAM provides the data at the selected address. During a write operation, data is stored on the rising edge of the clock when the write-enable signal is active. The byte-enable signals decide which bytes are written.

My block does not directly handle I/O transfers. I/O is handled by neighbouring I/O components, while my RAM communicates with the processor's datapath.

## E1 Instruction trace: SLTU
Trace one **SLTU** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

The instruction passes through these blocks in the RC-V processor:

Fetch – P14 PC and P30 ROM: The Program Counter provides the instruction address, and the ROM fetches the SLTU instruction.

Decode – P17, P21, P22/P23, P24: P17 extracts the instruction fields. P21 identifies the instruction class, and P22/P23 generate the control word. P24 selects the control signals.

Register Read – P13: The register file reads the values of rs1 and rs2.

Operand Selection – P26: The two register values are selected as the ALU inputs.

Execute – P10 and P01–P08: P10 generates the ALU control signal. The ALU performs an unsigned comparison and produces 1 or 0.

Write-back – P25, P11 and P12: P25 selects the ALU result, and the register file writes it into the destination register rd.

Next PC – P03, P15: The PC is updated to the next instruction address, normally PC + 4.

The SLTU instruction does not pass through P29 Data RAM because it compares register values directly and does not perform a memory read or write.

## E2 Neighbour review
Review the pull requests of P28 (Load extender) and P30 (Boot ROM). Paste the links to your review
comments here.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

My Data RAM belongs to the memory layer of the computer and is implemented using digital components such as decoders, multiplexers and flip-flops. It receives address, control and write-data signals from the processor datapath, and sends read data back to the datapath for use by load instructions.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 6).

- [X ] Logic gates, Boolean algebra, K-maps
- [X ] Combinational circuits (adders, decoders, encoders, multiplexers)
- [X ] Flip-flops, registers, counters
- [X ] Memory (RAM, ROM)
- [X ] Number systems, complements, signed arithmetic
- [ ] Bus organisation, instruction codes and formats
- [X ] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [X] Register organisation, stack, addressing modes
- [X ] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
