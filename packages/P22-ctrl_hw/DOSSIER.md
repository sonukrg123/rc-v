# P22 Hardwired control unit - dossier

## U1 Digital logic
For example, the `memwrite` output is 1 only for the STORE class in the supplied class test vectors. Its simplified Boolean expression is `memwrite = is_store`. The truth table is: `is_store=0 -> memwrite=0`; `is_store=1 -> memwrite=1`. The circuit uses combinational OR gates (and direct wiring for single-term equations); it needs no flip-flops because the output is a function only of the current instruction-class inputs.

## U2 Digital components
This block is combinational control logic. It uses OR gates to combine instruction-class signals for each control-word bit, with wires distributing the ten class inputs to the required equations. It does not contain adders, multiplexers, registers or memory; those are neighbouring datapath components controlled by this block.

## U3 Data representation
Three supplied one-hot test vectors are:
- LUI: `ctrl = 0x5830 = 0101 1000 0011 0000₂ = 22576₁₀`.
- JAL: `ctrl = 0x4144 = 0100 0001 0100 0100₂ = 16708₁₀`.
- BRANCH: `ctrl = 0x0028 = 0000 0000 0010 1000₂ = 40₁₀`.
These are unsigned control bit patterns, not signed arithmetic results. A common error is reversing bit order or confusing hexadecimal with decimal. Sign extension matters later when immediate values enter the datapath, but not when interpreting this 16-bit control word.

## U4 Computer organisation
P22 works during the DECODE step. The opcode decoder supplies instruction-class signals, and P22 converts them into control signals used by the datapath and later stages. The classes represented here are LUI, AUIPC, JAL, JALR, branch, load, store, OP-IMM, OP and SYSTEM.

## U5 Processors
A CISC processor may use more complex instruction decoding and may generate several internal micro-operations for one instruction. A stack machine would select operations around stack operands rather than the RISC-V register fields. A GPU has many execution lanes and typically distributes control across groups of similar operations; it still needs decode/control logic, but its organisation is designed for parallel execution.

## U6 Memory and I/O
P22 itself does not read or write memory or perform I/O. It asserts control signals for the relevant instruction class; neighbouring datapath and memory/I/O interface blocks perform the actual address, data and transfer operations. For example, LOAD and STORE class controls help select the memory path, while the memory and I/O interface handles the transfer.

## E1 Instruction trace: SLLI
SLLI is an OP-IMM instruction. The instruction is fetched from instruction ROM using the PC; decode extracts opcode, rd, rs1 and the shift-immediate fields. P21 identifies the OP-IMM class and P22 produces the OP-IMM control word (`0x5000` for the supplied class vector). The register file supplies rs1, the immediate-generation path supplies the zero-extended shift amount, and the ALU performs a logical left shift. The result is selected for write-back and written to rd; the PC advances to the next instruction. **The exact per-block signal values requested by the assignment must be copied from an actual RC-V `--trace` run; they are not fabricated here.**

## E2 Neighbour review
- P21 (Opcode class decoder) review comment link: **ADD THE URL OF YOUR ACTUAL REVIEW COMMENT**.
- P23 (Microprogrammed control / control ROM) review comment link: **ADD THE URL OF YOUR ACTUAL REVIEW COMMENT**.

## E3 Where my block sits
P22 sits in the control layer, implemented from combinational logic gates. It receives the instruction-class signals from the opcode decoder (P21) and produces a 16-bit control word consumed by datapath/control-selection blocks. It is not itself part of the arithmetic datapath or memory.

## E4 Syllabus map
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
