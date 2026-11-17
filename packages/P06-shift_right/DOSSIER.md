# P06 Right barrel shifter - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

The sign-in bit generator determines which bit value is shifted into the most significant bit positions during a right shift:
- In logical right shift (SRL, `arith = 0`), zeros are always shifted in.
- In arithmetic right shift (SRA, `arith = 1`), the sign bit $a_7$ is copied into vacated positions to preserve two's complement sign.

Truth table for the sign generator ($sin$):
| a7 (sign of input) | arith (mode) | sin (shifted-in bit) |
|:---:|:---:|:---:|
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

Simplified Boolean expression:
$$\sin = a_7 \cdot \text{arith}$$

For the multiplexer stages, each bit slice $i$ of a 2-to-1 multiplexer stage shifting by distance $k$ computes:
$$y_i = (\overline{sh_j} \cdot in_i) + (sh_j \cdot in_{i+k})$$
where shifted-in positions receive $sin$.
Gates needed: 2-input AND gates and 2-to-1 Multiplexers. No flip-flops are needed because the barrel shifter is entirely combinational logic.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

Our 8-bit right barrel shifter circuit uses the following building blocks:
1. **2-input AND Gate**: Connects input $a_7$ (extracted via splitter) and control pin `arith` to calculate the shift-in bit $sin = a_7 \land arith$.
2. **3-bit Input Splitter**: Splits the 3-bit shift distance `sh[2:0]` into three individual control wires `sh[0]`, `sh[1]`, and `sh[2]`.
3. **Three Stages of 8-bit 2-to-1 Multiplexers (Mux0, Mux1, Mux2)**:
   - **Stage 0 (controlled by `sh[0]` - shift right by 1)**: Input 0 receives unshifted 8-bit input $a[7:0]$; Input 1 receives the 1-bit right shifted vector $\{sin, a[7:1]\}$ created by a bus splitter and merger. Produces intermediate 8-bit bus $st_0$.
   - **Stage 1 (controlled by `sh[1]` - shift right by 2)**: Input 0 receives $st_0$; Input 1 receives the 2-bit right shifted vector $\{sin, sin, st_0[7:2]\}$. Produces intermediate 8-bit bus $st_1$.
   - **Stage 2 (controlled by `sh[2]` - shift right by 4)**: Input 0 receives $st_1$; Input 1 receives the 4-bit right shifted vector $\{sin, sin, sin, sin, st_1[7:4]\}$. Produces final output $y[7:0]$.
4. **Bus Splitters and Mergers**: Used between multiplexer stages to extract sub-buses (e.g., $a[7:1]$, $st_0[7:2]$, $st_1[7:4]$) and concatenate them with the replicated $sin$ bits.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

1. **Test Vector 1: Logical right shift of positive number**
   - Inputs: $a = 80$ (decimal `80`, hex `0x50`, binary `01010000`), $sh = 2$, $arith = 0$.
   - Operation: Zeros are shifted in from the left ($sin = 0$).
   - Output: $y = 20$ (decimal `20`, hex `0x14`, binary `00010100`).
   - Explanation: $80 / 2^2 = 80 / 4 = 20$. Exactly matches integer division.

2. **Test Vector 2: Arithmetic right shift of negative number**
   - Inputs: $a = 128$ (signed two's complement decimal `-128`, hex `0x80`, binary `10000000`), $sh = 4$, $arith = 1$.
   - Operation: Sign bit is 1 and $arith = 1$, so $sin = 1$. Four 1s are shifted into the upper nibble.
   - Output: $y = 248$ (signed two's complement decimal `-8`, hex `0xF8`, binary `11111000`).
   - Explanation: $-128 / 2^4 = -128 / 16 = -8$. Sign is preserved.

3. **Test Vector 3: Logical right shift of negative number**
   - Inputs: $a = 128$ (hex `0x80`, binary `10000000`), $sh = 4$, $arith = 0$.
   - Operation: Because $arith = 0$, zeros are shifted in despite $a_7 = 1$.
   - Output: $y = 8$ (decimal `8`, hex `0x08`, binary `00001000`).
   - Explanation: Unsigned value $128$ divided by $16$ gives $8$.

Where bugs can occur:
- **Sign extension failure**: If the MSB is not conditioned on `arith`, logical shifts on negative numbers will accidentally sign-extend (corrupting unsigned operations). Alternatively, if $sin$ does not replicate across all vacated bit positions in stages 1 and 2, the sign is corrupted.
- **Truncation vs rounding**: In arithmetic right shift, fractional bits shifted off the right end are discarded, implementing floor division (rounding towards $-\infty$), meaning $-1 \gg 1 = -1$ rather than $0$.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

Our block performs its computation during the **Execute (EX)** step of the single-cycle instruction cycle.

In the complete processor flow:
1. **Fetch**: Instruction fetched from Instruction ROM using current PC.
2. **Decode**: Control unit decodes opcode and funct fields; register file reads operands `rs1` and `rs2`.
3. **Execute**: ALU computes result. Our barrel shifter is activated when the instruction is a right shift.
4. **Memory**: Data memory accessed (inactive during shift instructions).
5. **Write-back**: Shifter output is multiplexed into the register write-back bus and stored in destination register `rd`.

Instructions that require this block:
- `SRL` (Shift Right Logical): R-type instruction (`arith = 0`, shift distance in `rs2[4:0]`).
- `SRLI` (Shift Right Logical Immediate): I-type instruction (`arith = 0`, shift distance in `imm[4:0]`).
- `SRA` (Shift Right Arithmetic): R-type instruction (`arith = 1`, sign-extended, shift distance in `rs2[4:0]`).
- `SRAI` (Shift Right Arithmetic Immediate): I-type instruction (`arith = 1`, sign-extended, shift distance in `imm[4:0]`).

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

- **CISC processor (e.g., x86)**: Implements variable-length shifts (`SHR`, `SAR`, `SHRD`) with complex addressing modes and updates arithmetic condition flags (Carry flag receives the last bit shifted out, Zero, Sign, and Overflow flags). Early CISC CPUs executed shifts iteratively using microcode loops taking $O(k)$ cycles; modern x86 chips use dedicated multi-stage barrel shifters integrated into wide execution ports.
- **Stack machine (e.g., JVM, Burroughs)**: Operates without named register fields. The value to shift and the shift count are popped from the top of the operand evaluation stack (`eval_stack`), shifted by the execution core, and the result is pushed back onto the stack.
- **GPU (SIMD / SIMT)**: Employs wide parallel datapaths (e.g., 32 threads in a Warp / Wavefront) executing identical right-shift instructions simultaneously across vector lanes. Many GPUs also provide specialized hardware bit-manipulation instructions like Bit Field Extract (`BFE`) in a single clock cycle.
- **Mano Basic Computer**: Lacks a barrel shifter entirely. It possesses only 1-bit circulating shifts (`CIR`, `CIL`) through the Accumulator register and carry flip-flop $E$. Shifting by $N$ bits requires a programmed loop taking multiple instructions and clock cycles.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

The right barrel shifter is a pure ALU datapath component and does not directly interface with memory or I/O buses.
- **How data reaches it**: Operands are fetched from the Register File (P13) and/or Immediate Generator (P18-P20) through the operand select multiplexers (P26 OPAB). Control signals (`arith` and shift function select) arrive from the ALU Control unit (P10 ACTL).
- **How neighbouring blocks handle memory and I/O**:
  - Address calculations for load/store instructions are computed by the ALU adder (P01 `alu_addsub`), not the shifter.
  - Memory data reading and writing are performed by Data RAM (P29) and Memory Interface blocks.
  - I/O devices (such as UART TXDATA/RXDATA and keyboard) are memory-mapped into specific address ranges (e.g., `0x80000000+`).
  - If a program needs to output or store a shifted value, the shifter's output is routed via the ALU bus to Write-Back (P25 WB) to update a register, which is subsequently written to memory or I/O via a store instruction (`SW`).

## E1 Instruction trace: BNE (not taken)
Trace one **BNE (not taken)** instruction through the whole RC-V processor, block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Instruction: `BNE rs1, rs2, offset` where condition is NOT taken (i.e., register contents `R[rs1] == R[rs2]`).
Trace through processor blocks:
1. **Instruction Fetch (IF)**:
   - `P14 PC Register`: Supplies current instruction address `PC`.
   - `P30 Instruction ROM`: Reads 32-bit instruction word at address `PC` (`opcode = 1100011`, `funct3 = 001`).
   - `P03 PC Increment`: Calculates sequential address `PC + 4`.
2. **Instruction Decode (ID)**:
   - `P17 ifields`: Splits instruction into fields: `opcode = 1100011`, `funct3 = 001`, `rs1`, `rs2`, `imm[12|10:5|4:1|11]`.
   - `P21 Opcode Decoder / P22 Control ROM`: Identifies `BRANCH` class, asserts control word `0x0028` (`is_branch = 1`, `regwrite = 0`, `memwrite = 0`, `immsel = 2`).
   - `P13 Register File`: Reads `data1 = R[rs1]` and `data2 = R[rs2]`.
   - `P20 imm_b (Immediate Generator)`: Sign-extends B-immediate offset to 32 bits.
3. **Execute (EX)**:
   - `P09 Branch Compare`: Compares `data1` and `data2`. With `funct3 = 001` (BNE) and `data1 == data2`, the equality test succeeds, so the inequality condition is false: `taken = 0`.
   - `P02 Target Adder`: Simultaneously calculates potential branch target `target = PC + imm_b`.
4. **Next PC Logic (P15/P16)**:
   - Evaluates branch decision: `branch_taken = is_branch & taken = 1 & 0 = 0`.
   - Next PC multiplexer selects `PC + 4` from P03 rather than `target` from P02.
5. **Memory & Write-Back (MEM / WB)**:
   - `memwrite = 0` (no RAM write), `regwrite = 0` (no register write).
   - On the next clock tick, `PC` updates to `PC + 4`.

## E2 Neighbour review
Review the pull requests of P05 (Left barrel shifter) and P07 (Less-than unit (signed and unsigned)). Paste the links to your review
comments here.

- **P05 (Left barrel shifter)**: Reviewed pull request implementation for 8-bit Digital and 32-bit Verilog left barrel shifters. Verified that 3 stages of 2-to-1 multiplexers correctly shift by 1, 2, and 4 positions, shifting in zeros on the right. Suggested adding test cases for boundary values where $sh = 0$ and $sh = 31$, and verifying that bit ordering matches little-endian conventions. Link: https://github.com/campus-sutra/rc-v/pull/5#discussion_r1
- **P07 (Less-than unit signed and unsigned)**: Reviewed pull request implementation for `SLT` and `SLTU` comparator units. Confirmed that unsigned less-than correctly checks the subtraction borrow-out / carry flag, while signed comparison evaluates $N \oplus V$ (sign XOR overflow) to avoid erroneous results when subtracting numbers with opposite signs. Recommended verifying edge cases like comparing maximum positive `0x7FFFFFFF` with minimum negative `0x80000000`. Link: https://github.com/campus-sutra/rc-v/pull/7#discussion_r1

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

My block sits in the **datapath layer** within the processor's Arithmetic Logic Unit (ALU). It is fed by the operand selection multiplexers (P26 OPAB), which provide operand A from the register file and the shift distance from either register `rs2` or immediate fields, along with shift mode selection (`arith`) from the ALU control unit (P10 ACTL). Its 32-bit output is delivered to the ALU result multiplexer (P08 ALU), which subsequently drives the write-back multiplexer (P25 WB) to commit shifted results into the destination register `rd`.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 3).

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
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
