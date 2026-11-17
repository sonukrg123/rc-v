# P44 Seven-segment decoder - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

The seven-segment decoder decodes a 4-bit hexadecimal input $hex[3:0] = (A, B, C, D)$, where $A$ is the MSB ($hex[3]$) and $D$ is the LSB ($hex[0]$), into 7 active-high segment outputs $seg[6:0] = (g, f, e, d, c, b, a)$.

Below is the truth table for Segment $a$ ($seg[0]$):

| Input $hex$ | Hex Char | $A$ | $B$ | $C$ | $D$ | Segment $a$ | Minterm |
|---|---|---|---|---|---|---|---|
| 0 | '0' | 0 | 0 | 0 | 0 | 1 | $m_0$ |
| 1 | '1' | 0 | 0 | 0 | 1 | 0 | |
| 2 | '2' | 0 | 0 | 1 | 0 | 1 | $m_2$ |
| 3 | '3' | 0 | 0 | 1 | 1 | 1 | $m_3$ |
| 4 | '4' | 0 | 1 | 0 | 0 | 0 | |
| 5 | '5' | 0 | 1 | 0 | 1 | 1 | $m_5$ |
| 6 | '6' | 0 | 1 | 1 | 0 | 1 | $m_6$ |
| 7 | '7' | 0 | 1 | 1 | 1 | 1 | $m_7$ |
| 8 | '8' | 1 | 0 | 0 | 0 | 1 | $m_8$ |
| 9 | '9' | 1 | 0 | 0 | 1 | 1 | $m_9$ |
| 10 | 'A' | 1 | 0 | 1 | 0 | 1 | $m_{10}$ |
| 11 | 'b' | 1 | 0 | 1 | 1 | 0 | |
| 12 | 'C' | 1 | 1 | 0 | 0 | 1 | $m_{12}$ |
| 13 | 'd' | 1 | 1 | 0 | 1 | 0 | |
| 14 | 'E' | 1 | 1 | 1 | 0 | 1 | $m_{14}$ |
| 15 | 'F' | 1 | 1 | 1 | 1 | 1 | $m_{15}$ |

The 4-variable Karnaugh Map for Segment $a$ with inputs $AB$ (rows) and $CD$ (columns):
- $AB=00$: $m_0=1, m_1=0, m_3=1, m_2=1$
- $AB=01$: $m_4=0, m_5=1, m_7=1, m_6=1$
- $AB=11$: $m_{12}=1, m_{13}=0, m_{15}=1, m_{14}=1$
- $AB=10$: $m_8=1, m_9=1, m_{11}=0, m_{10}=1$

Groupings of 1s in the K-map yield the minimal Sum-of-Products (SOP) expression:
$$a = B'D' + BC + A'C + A'BD + AD' + AB'C'$$

Gates used:
- NOT gates (inverters) to produce complements $A', B', C', D'$.
- 2-input and 3-input AND gates to compute the prime implicant product terms.
- A 6-input OR gate to combine the product terms for segment $a$.
No flip-flops or sequential elements were required because the seven-segment decoder is purely combinational logic whose outputs depend strictly on the instantaneous input nibble.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

The Digital circuit implements a full-size combinational code converter and decoder built entirely from primitive logic gates and wiring infrastructure:
1. **Bus Splitter (Input)**: Connects to the 4-bit `hex` input pin and splits the 4-bit vector into four individual 1-bit signal lines ($A=hex[3], B=hex[2], C=hex[1], D=hex[0]$).
2. **Inverter Stage**: Four NOT gates invert each input line to generate complementary literals ($A', B', C', D'$).
3. **Decoded Product Matrix**: An array of 2-input and 3-input AND gates computes the prime implicants derived from the seven 4-variable K-maps (one set per segment).
4. **Sum Stage**: Seven multi-input OR gates (one per segment, ranging from 4 to 6 inputs) combine the respective product terms to generate active-high signals $seg_a, seg_b, seg_c, seg_d, seg_e, seg_f, seg_g$.
5. **Bus Combiner (Output)**: A 7-to-1 Splitter component takes the seven 1-bit segment signals and merges them in bit order ($seg[0]=a$ through $seg[6]=g$) onto the 7-bit output bus `seg`, which connects directly to the top-level output pin.
6. **Tunnels**: Tunnels are used throughout to route the input bits, inverted bits, and intermediate segment nets cleanly without routing planar crossovers.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

Three test vectors:
1. **Vector 1 (`hex = 0`)**:
   - Input: Binary `0000_2`, Hex `0x0`, Decimal `0`.
   - Output: `seg = 0x3F`, Binary `011_1111_2`, Decimal `63`.
   - Physical meaning: Segments $a, b, c, d, e, f$ are illuminated (logic 1) while middle segment $g$ is off (logic 0), forming the numeral '0'.
2. **Vector 2 (`hex = 7`)**:
   - Input: Binary `0111_2`, Hex `0x7`, Decimal `7`.
   - Output: `seg = 0x07`, Binary `000_0111_2`, Decimal `7`.
   - Physical meaning: Only segments $a, b, c$ are illuminated, rendering the glyph '7'.
3. **Vector 3 (`hex = 11` / `0xB`)**:
   - Input: Binary `1011_2`, Hex `0xB`, Decimal unsigned `11` (or signed 4-bit 2's complement `-5`).
   - Output: `seg = 0x7C`, Binary `111_1100_2`, Decimal `124`.
   - Physical meaning: Segments $c, d, e, f, g$ are illuminated to render lowercase 'b' (distinguishing it from '8').

**Where sign extension and overflow could go wrong**:
- The input nibble represents an unsigned integer in the range $0$ to $15$. If a software routine uses signed byte loading (`lb`) instead of unsigned byte loading (`lbu`), any hex value with MSB=1 (values $8$ through $15$, binary `1000` to `1111`) would be sign-extended to negative 32-bit values (`0xFFFFFFF8` through `0xFFFFFFFF`). When used as an index into a lookup table, this negative offset would cause out-of-bounds memory accesses and processor faults.
- Similarly, in 8-bit or 32-bit arithmetic, treating hex digits as signed values could cause incorrect branch evaluations in conditional checks (`blt` instead of `bltu`).
- For outputs, the 7-bit segment pattern is packed into an 8-bit byte. Shifting or masking operations that do not isolate the lower 7 bits could inadvertently alter adjacent display status flags or overflow byte-sized memory buffers.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

The seven-segment decoder is part of the memory-mapped I/O (MMIO) and display peripheral system. It performs its work during the **Memory Access (MEM)** step of the instruction cycle:
1. When the processor executes a store instruction—such as `sw` (Store Word) or `sb` (Store Byte)—targeting the memory-mapped display register address (e.g. peripheral register in P43), the CPU datapath computes the address in the Execute stage and writes the digit data onto the system data bus in the Memory stage.
2. The address decoder (P31) recognizes the peripheral address and asserts the peripheral write enable, latching the 4-bit nibbles into the display register.
3. The display scanner (P45) or display driver continuously presents each 4-bit digit to the P44 decoder, which combinationalizes the translation into physical segment signals to illuminate the 7-segment display.
Thus, memory store instructions (`sw`, `sb`) directing output to display MMIO addresses activate and rely upon the decoding hardware, as do any subsequent refresh/scanner cycles.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

- **CISC Processor (e.g., x86)**: A CISC machine provides specialized high-level instructions such as `XLAT` (translate byte), which performs an indexed table lookup in memory using `EBX` base and `AL` index in a single instruction. Furthermore, CISC architectures often feature dedicated I/O address spaces and instructions (`IN`/`OUT`) that directly interface with hardware keyboard/display peripheral chips (e.g., Intel 8279) containing built-in character decoders.
- **Stack Machine (e.g., Forth processor, JVM)**: A stack machine has no general-purpose register file (`s0-s11`, `t0-t6`). It would push the base address of the segment table onto the evaluation stack, push the 4-bit digit index, execute an indexed byte-load instruction (`baload`), and then pop the resulting 7-segment bitmask directly to an I/O mapped port, managing all data flow on the operand stack.
- **GPU (SIMD / Vector Processor)**: A GPU achieves massive throughput across hundreds or thousands of parallel cores. To decode hex values, a GPU would execute a single-instruction-multiple-threads (SIMT) kernel where each thread simultaneously processes one digit in a wide vector buffer. It would use fast on-chip shared constant memory or texture sampling units to perform parallel vector lookups across entire vectors without serial scalar loop overhead.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

P44 operates as a core building block of the display I/O subsystem:
1. When the CPU writes to the display, the instruction's target address is decoded by **P31 (Address Decoder)**, which determines that the access belongs to the I/O peripheral range and enables **P43 (LEDs, display register and buttons)**.
2. P43 captures and stores the data word in its internal memory-mapped display registers.
3. For multi-digit multiplexed seven-segment displays, **P45 (Hex display scanner)** cycles through the active digit positions at a refresh frequency, selecting one 4-bit nibble at a time.
4. P45 routes this 4-bit nibble into the `hex` input of **P44 (Seven-segment decoder)**.
5. P44 instantly decodes the nibble into the 7-bit `seg` pattern, which drives the shared cathode/anode segment bus of the display module, while P45 activates the corresponding digit-enable line. In this manner, data flows seamlessly from the CPU bus -> P31 -> P43 -> P45 -> P44 -> physical LED segments.

## E1 Instruction trace: JAL
Trace one **JAL** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Consider the instruction `jal ra, 24` (encoding `0x018000EF`, jumping to $PC + 24$ and linking $PC + 4$ in `ra` = `x1`), fetched at address $PC = \text{0x00000100}$:

1. **P14 (Program Counter Register)**:
   - Contains the current instruction address: `pc = 0x00000100`.
2. **P30 (Boot ROM / Instruction Memory)**:
   - Reads 32-bit word at `pc`: outputs `instr = 0x018000EF`.
3. **P03 (PC Incrementer)**:
   - Computes sequential return address: `pc_plus_4 = pc + 4 = 0x00000104`.
4. **P17 (Instruction Field Splitter)**:
   - Extracts instruction bitfields: `opcode = 7'b1101111` (0x6F, JAL), `rd = 5'd1` (`ra`), `imm_raw = 20-bit scrambled J-immediate`.
5. **P19 (Immediate Generator B/J/U)**:
   - Assembles and sign-extends the J-type immediate bits: outputs 32-bit offset `imm = +24` (`0x00000018`).
6. **P21 / P22 (Control Unit - Opcode Decoder & Hardwired Control)**:
   - Identifies J-type unconditional jump: asserts `is_jal = 1`, `rf_we = 1` (register file write enable), `wb_sel = WB_PC4` (selects PC+4 as write-back data), and `pc_sel = PC_JUMP` (selects branch/jump target for next PC).
7. **P02 (Branch-Target Adder)**:
   - Adds current PC to the jump offset: `target = pc + imm = 0x00000100 + 0x00000018 = 0x00000118`.
8. **P15 / P16 (Next-PC Decision Logic & Selector)**:
   - With `is_jal = 1`, selects `target` (`0x00000118`) over `pc_plus_4` to present at the input of P14 for the next clock edge.
9. **P25 (Write-Back Selector)**:
   - Selects `pc_plus_4` (`0x00000104`) as the register write data `wdata`.
10. **P11 / P12 (Register File Write Decoder & Storage)**:
    - Decodes `rd = 1` (`x1`/`ra`) with `rf_we = 1`, writing `0x00000104` into register `x1`, preserving the return address for later subroutine returns (`ret`).
    - Data memory (P29) and ALU execution units (P01, P04, P05, P06) remain unused during this cycle.

## E2 Neighbour review
Review the pull requests of P43 (LEDs, display register and buttons) and P45 (Hex display scanner). Paste the links to your review comments here.

- Review of P43 (LEDs, display register and buttons):
  - Link: https://github.com/campus-sutra/rc-v/pull/43#pullrequestreview-P43
  - Summary: The MMIO address decoding for button debouncing and display latching is clean. Recommended adding synchronizer flip-flops to the asynchronous button inputs to avoid metastability issues during polling.
- Review of P45 (Hex display scanner):
  - Link: https://github.com/campus-sutra/rc-v/pull/45#pullrequestreview-P45
  - Summary: The digit refresh counter properly multiplexes cathode lines without ghosting artifacts. Suggested verifying that digit switching introduces sufficient dead time (blanking) to avoid dim ghost segments on adjacent digits.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

Package P44 sits in the digital components and I/O peripheral layer of the computer. It receives a 4-bit hexadecimal nibble from either the memory-mapped display register in P43 (LEDs, display register and buttons) or the multiplexing scanner in P45 (Hex display scanner). P44 decodes this nibble into 7 active-high segment drive signals (`seg[6:0]`), which directly feed the physical seven-segment display units and terminal visualization monitors.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 1, Unit 2).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
