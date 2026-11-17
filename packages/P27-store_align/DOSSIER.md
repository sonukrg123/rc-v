# P27 Store aligner - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

**Truth table for Store Byte (`sb`, `funct3 = 000`) byte-enable `be[3:0]` generation:**

| `addr_lo[1]` ($A_1$) | `addr_lo[0]` ($A_0$) | `be[3]` | `be[2]` | `be[1]` | `be[0]` | Hex (`be`) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 0 | 0 | 0 | 0 | 0 | 1 | `0x1` |
| 0 | 1 | 0 | 0 | 1 | 0 | `0x2` |
| 1 | 0 | 0 | 1 | 0 | 0 | `0x4` |
| 1 | 1 | 1 | 0 | 0 | 0 | `0x8` |

**Simplified Boolean expressions:**
* $\text{be}[0] = \overline{A_1} \cdot \overline{A_0}$
* $\text{be}[1] = \overline{A_1} \cdot A_0$
* $\text{be}[2] = A_1 \cdot \overline{A_0}$
* $\text{be}[3] = A_1 \cdot A_0$

**Gates / flip-flops needed:**
* None. The block is purely combinational and is built entirely out of **Multiplexers**, **Bit Splitters/Mergers**, and **Constants** (no standalone gates or flip-flops were used).

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

* **Building blocks used:** Multiplexers, bit splitters/mergers, and constants (no adders, registers, or memory blocks).
* **Connections:**
  * **Byte-enable (`be`) path:** `addr_lo[1:0]` drives the selector pins of two 2-bit-selector multiplexers—one selects the 4-bit byte mask (`0x1, 0x2, 0x4, 0x8`) for `sb`, and the other selects the half-word mask (`0x3` or `0xC`) for `sh`. A 3-bit-selector multiplexer controlled by `funct3` chooses between the `sb` mask (input `0`), `sh` mask (input `1`), `0xF` for `sw` (input `2`), and `0x0` for unused opcodes (inputs `3–7`) to output `be`.
  * **Write-data (`wdata`) path:** Splitters and mergers replicate `rs2[7:0]` four times into a 32-bit word (`wdata_sb`) and `rs2[15:0]` twice into a 32-bit word (`wdata_sh`). A second 3-bit-selector multiplexer controlled by `funct3` selects `wdata_sb` (`0`), `wdata_sh` (`1`), unmodified `rs2` (`2`), or `0` (`3–7`) to output `wdata`.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

1. **Store Byte (`sb`) to lane 2:**
   * **Inputs:** `funct3 = 000₂` (`0x0`, `0`), `addr_lo = 10₂` (`0x2`, `2`), `rs2 = 0x123456AB` (lowest byte = `10101011₂`, `0xAB`, `171` unsigned / `-85` signed two's complement).
   * **Outputs:** `be = 0100₂` (`0x4`, `4`), `wdata = 0xABABABAB` (`2,880,154,539` unsigned / `-1,414,812,757` signed).
2. **Store Half-word (`sh`) to upper half-word:**
   * **Inputs:** `funct3 = 001₂` (`0x1`, `1`), `addr_lo = 10₂` (`0x2`, `2`), `rs2 = 0x0000BEEF` (lowest 16 bits = `1011111011101111₂`, `0xBEEF`, `48,879` unsigned / `-16,657` signed).
   * **Outputs:** `be = 1100₂` (`0xC`, `12`), `wdata = 0xBEEFBEEF` (`3,203,383,023` unsigned / `-1,091,584,273` signed).
3. **Store Word (`sw`) aligned:**
   * **Inputs:** `funct3 = 010₂` (`0x2`, `2`), `addr_lo = 00₂` (`0x0`, `0`), `rs2 = 0xDEADBEEF` (`3,735,928,559` unsigned / `-559,038,737` signed).
   * **Outputs:** `be = 1111₂` (`0xF`, `15`), `wdata = 0xDEADBEEF`.

**Where overflow or sign extension could go wrong:**
* Store alignment moves raw bit patterns into target byte lanes rather than performing arithmetic. If `rs2[7:0]` or `rs2[15:0]` were sign-extended instead of replicated into the matching byte lanes, the target lane would receive sign bits instead of the stored data.
* Unaligned offsets (such as `addr_lo = 01` or `11` during `sh`) cannot place a 16-bit half-word onto a 2-byte boundary inside a single 32-bit word without overflowing into an adjacent word.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

* **Instruction cycle step:** **Memory (`MEM`)** stage, preparing the aligned write data and byte-enable mask before data memory (or memory-mapped I/O) latches the write, using the low 2 address bits computed during the **Execute (`EX`)** stage.
* **Instructions that need it:** All RISC-V store instructions—**`sb`** (`funct3 = 000`), **`sh`** (`funct3 = 001`), and **`sw`** (`funct3 = 010`).

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

* **CISC processor (e.g., x86):** Supports unaligned, arbitrary byte-width memory writes directly in hardware/microcode by splitting cross-word stores into multiple memory bus cycles rather than requiring aligned 32-bit lane replication and explicit `be[3:0]` masks.
* **Stack machine / Mano-style CPU:** As seen in the Mano architecture comparison, memory transfers operate on fixed full-word widths (16-bit `M[AR]`) without sub-word byte-enable lines (`be[3:0]`); storing a single byte requires a multi-instruction read-modify-write sequence (load word, mask and shift bits in registers, store full word back).
* **GPU:** Uses a **memory coalescing unit** across an entire warp/wavefront of threads to combine per-thread byte/word stores into wide cache-line transactions (e.g., 128-byte lines) with per-byte write masks, serializing unaligned or divergent addresses into multiple transactions.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

* In RISC-V, I/O is **memory-mapped (MMIO)**, so both RAM writes and peripheral register writes travel over the same data memory bus (`addr`, `wdata`, `be`, `we`).
* My block sits immediately upstream of the **Data Memory / MMIO bus interface**: it formats `rs2` into the 32-bit aligned `wdata` bus and asserts the corresponding `be[3:0]` byte-enable lines so only the targeted byte(s) in RAM or a memory-mapped device register are updated during a store cycle.

## E1 Instruction trace: SLL
Trace one **SLL** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Example instruction: **`sll x3, x1, x2`** (`rd = x3`, `rs1 = x1`, `rs2 = x2`, `opcode = 0110011`, `funct3 = 001`, `funct7 = 0000000`), with `PC = 0x00000000`, `x1 = 0x00000005`, and `x2 = 0x00000003`:

1. **PC Register & Instruction Memory (`IMEM`):**
   * `pc = 0x00000000` fetches `instr = 0x002091B3` (`sll x3, x1, x2`).
   * `PC + 4` adder computes `pc_next = 0x00000004`.
2. **Decoder / Field Extractor (`P17`):**
   * Extracts `opcode = 0110011` (R-type), `rd = 3`, `rs1 = 1`, `rs2 = 2`, `funct3 = 001`, `funct7 = 0000000`.
3. **Main Control & ALU Control (`P21` / `P22`):**
   * Sets `RegWrite = 1`, `MemRead = 0`, `MemWrite = 0`, `ALUSrc = 0` (selects `rs2`), `ResultSrc = 0` (selects ALU output), `Branch = 0`, `Jump = 0`, and `ALUOp = SLL` (`0001`).
4. **Register File (`REGFILE`):**
   * Reads `rs1_data = 0x00000005` (`x1`) and `rs2_data = 0x00000003` (`x2`).
5. **ALU (`ALU`):**
   * Shifts `rs1_data` left logically by `rs2_data[4:0] = 3` bits: `alu_result = 0x00000005 << 3 = 0x00000028` (`40` decimal).
6. **Store Aligner (`P27`, my block) & Data Memory (`DMEM`):**
   * Bypassed/inactive because `MemWrite = 0` (`be` is ignored by `DMEM`, and no memory write occurs).
7. **Write-Back Mux & Register File:**
   * `ResultSrc = 0` routes `wb_data = 0x00000028` back to the Register File; on the rising clock edge, `x3` is updated to `0x00000028` and `PC` updates to `0x00000004`.

## E2 Neighbour review
Review the pull requests of P36 (Cache statistics counters) and P28 (Load extender). Paste the links to your review
comments here.

* **P36 (Cache statistics counters) review:** `<paste your GitHub PR comment URL here>`
* **P28 (Load extender) review:** `<paste your GitHub PR comment URL here>`

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

My block sits in the **datapath layer** (between the Execution stage and the Memory/MMIO interface). It is fed by the **Register File** (`rs2`), the **Instruction Decoder** (`funct3`), and the **ALU address output** (`addr_lo[1:0]`). Its outputs (`wdata[31:0]` and `be[3:0]`) directly drive the **Data Memory (`DMEM`) / memory-mapped I/O** write interface.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 6).

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
- [x] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
