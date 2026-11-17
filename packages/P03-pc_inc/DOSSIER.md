# P03 PC incrementer - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic

For a single cascaded half-adder stage at bit $i$ ($3 \le i \le 6$), taking input bit $A = \text{pc}[i]$ and carry-in $C_{\text{in}}$ to produce sum bit $S = \text{pc4}[i]$ and carry-out $C_{\text{out}}$:

| $\text{pc}[i]$ | $C_{\text{in}}$ | $\text{pc4}[i]$ ($S$) | $C_{\text{out}}$ |
| :---: | :---: | :---: | :---: |
| 0 | 0 | 0 | 0 |
| 0 | 1 | 1 | 0 |
| 1 | 0 | 1 | 0 |
| 1 | 1 | 0 | 1 |

- **Simplified Boolean Expressions:**
  - Bit 2: $\text{pc4}[2] = \overline{\text{pc}[2]}$, $\quad C_3 = \text{pc}[2]$
  - Bits 3–6: $\text{pc4}[i] = \text{pc}[i] \oplus C_i$, $\quad C_{i+1} = \text{pc}[i] \cdot C_i$
  - Bit 7: $\text{pc4}[7] = \text{pc}[7] \oplus C_7$
- **Gates Used:** Purely combinational logic using **1 `NOT` gate**, **5 `XOR` gates**, and **4 `AND` gates** (no flip-flops needed).

## U2 Digital components

- **Building Blocks Used:** The circuit uses **cascaded half-adders** built from basic gates (`NOT`, `XOR`, `AND`) along with an **8-bit input splitter (`pc`)** and an **8-bit output merger (`pc4`)**. No multiplexers, decoders, registers, or memory elements are inside this block.
- **How They Are Connected:**
  - Bits `0` and `1` pass straight from `pc` to `pc4` because adding `4` (`00000100₂`) never changes the lowest two bits.
  - Bit `2` passes through a `NOT` gate to `pc4[2]`, while its uninverted value acts as $C_3$.
  - Bits `3` through `6` each connect to a half-adder (`XOR` for sum, `AND` for carry-out) chained sequentially so $C_{i+1}$ feeds bit $i+1$.
  - Bit `7` connects with $C_7$ into a final `XOR` gate to produce `pc4[7]`.

## U3 Data representation

1. **Vector 1 (Normal sequential step):**
   - `pc` = `00000000₂` = `0x00` = `0`
   - `pc4` = `00000100₂` = `0x04` = `4`
2. **Vector 2 (Carry ripple across multiple bits):**
   - `pc` = `00011100₂` = `0x1C` = `28`
   - `pc4` = `00100000₂` = `0x20` = `32` (carry propagates from bit 2 through bits 3 and 4 into bit 5)
3. **Vector 3 (8-bit wrap-around / unsigned overflow):**
   - `pc` = `11111100₂` = `0xFC` = `252` (or `-4` if interpreted as 8-bit two's complement signed)
   - `pc4` = `00000000₂` = `0x00` = `0` (the carry out of bit 7 is discarded)
- **Overflow & Sign Extension Issues:** Program Counter addresses are **unsigned** values. If `pc` were mistakenly sign-extended from 8 bits to 32 bits, addresses $\ge \text{0x80}$ (`128`) would turn into negative numbers (`0xFFFFFF80`) instead of `0x00000080`. Also, at `0xFC`, adding `4` overflows 8 bits and wraps back to `0x00`.

## U4 Computer organisation

- **Instruction Cycle Step:** The PC incrementer operates during the **Fetch (IF)** stage (computing the sequential next-instruction address `PC + 4` in parallel while instruction memory is being read).
- **Which Instructions Need It:** **Every instruction** uses `PC + 4`—sequential instructions (`ADD`, `LW`, `SW`, `BEQ` when not taken) load `pc4` directly into the `PC` register, while `JAL` and `JALR` also save `PC + 4` into destination register `rd` as the return address.

## U5 Processors

- **CISC Processor (e.g., x86 / Mano's Basic Computer):** Instructions have **variable byte lengths** (1 to 15 bytes in x86, or 16-bit/1-word steps in Mano's machine). Instead of a fixed `+4` hardware incrementer, the CPU increments `PC` by `+1` per fetched byte/word during decode or adds the decoded instruction length dynamically.
- **Stack Machine (e.g., JVM bytecode):** Bytecode instructions are 1 byte long with variable-length inline operands, so `PC` advances by `+1` as each bytecode or operand byte is fetched rather than jumping by a fixed 4-byte word.
- **GPU (SIMT Architecture):** A single warp/wavefront shares one `PC` across 32 threads using an active execution mask; during branch divergence, hardware manages a divergence stack of `PC` values rather than a simple single-stream `+4` path.

## U6 Memory and I/O

- **Direct Role:** The PC incrementer does **not** directly read/write data memory or perform I/O transfers; it only calculates `PC + 4`.
- **Neighbouring Blocks:** The **`PC` register** feeds the current instruction address to **Instruction Memory (`IMEM`)** to fetch the next 32-bit instruction, while the **ALU** (neighbouring execution block) computes effective addresses (`rs1 + imm`) for `LW`/`SW` data memory and memory-mapped I/O transfers.

## E1 Instruction trace: JAL

Tracing `JAL x1, offset` through the RC-V datapath:
1. **Fetch (`PC` & `IMEM` & `PC Incrementer`):** `PC` outputs the current address `pc` to `IMEM` and the `PC Incrementer`. `IMEM` outputs the 32-bit `JAL` instruction word (`opcode = 1101111`), while the PC incrementer outputs `pc4 = pc + 4`.
2. **Decode (`Control Unit` & `Immediate Generator`):** Control asserts `RegWrite = 1`, selects `pc4` for write-back (`MemtoReg / WBSel = PC+4`), and sets `PCSel = jump`. The Immediate Generator extracts and sign-extends the 20-bit J-type immediate (`imm_J`, shifted left by 1).
3. **Execute (`Branch/Jump Target Adder`):** The target adder computes `target = pc + imm_J`.
4. **Memory (`DMEM`):** Idle (`MemRead = 0`, `MemWrite = 0`).
5. **Write-Back (`Register File` & `PC`):** `pc4` (`pc + 4`) is written into `rd` (`x1`) as the return address, and `PC` is updated to `target` on the next clock edge.

## E2 Neighbour review

- P02 (Branch-target adder (carry look-ahead)) review: https://github.com/campus-sutra/rc-v/pull/132
- P04 (ALU logic unit) review: https://github.com/campus-sutra/rc-v/pull/134

## E3 Where my block sits

The PC incrementer sits in the **datapath layer** (built from combinational **gate/component** primitives). It is fed directly by the **`PC` register**, and its output (`pc4`) feeds both the **`PC` next-state multiplexer** (for sequential instruction fetch) and the **register file write-back multiplexer** (to save return addresses for `JAL`/`JALR`).

## E4 Syllabus map

Tick every syllabus topic your work touched (main units: Unit 2).

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
