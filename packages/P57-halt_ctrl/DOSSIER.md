# P57 Halt controller - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
The P57 Halt Controller uses a sticky HALT flip-flop.

The HALT output becomes 1 when either:
- A HALT register write requests a halt.
- A committed instruction equals `0x0000006F` (the RISC-V `j .` instruction).

The HALT output remains 1 until reset.

The Boolean expression is:

`H_next = NOT(rst) AND (H OR write_halt OR (commit AND instruction_match))`

Where:
- H is the current HALT state.
- `write_halt` is the HALT register write request.
- `instruction_match` is true when the instruction equals `0x0000006F`.

The circuit uses a 32-bit comparator, AND gates, OR gates, an inverter and a D flip-flop.

## U2 Digital components
The P57 Digital circuit uses the following components:

- **32-bit comparator:** compares the committed instruction with `0x0000006F`.
- **AND gates:** combine the commit signal with the comparator result and combine the halt request with the reset condition.
- **OR gates:** combine the different halt conditions and the previous HALT state.
- **Inverter:** provides the active reset condition.
- **D flip-flop:** stores the HALT state and keeps it set until reset.

The comparator output passes through AND/OR logic to the D input of the flip-flop. The flip-flop output provides the `halted` signal and feedback for sticky HALT behaviour.

## U3 Data representation
The P57 controller uses 32-bit instruction values and register data.

Three useful test values are:

| Value | Binary (32-bit) | Hexadecimal | Decimal |
|---|---|---|---:|
| Package number 57 | `00000000000000000000000000111001` | `0x00000039` | 57 |
| HALT instruction (`j .`) | `00000000000000000000000001101111` | `0x0000006F` | 111 |
| HALT register set | `00000000000000000000000000000001` | `0x00000001` | 1 |

The comparator checks the complete 32-bit instruction value. A wrong bit or incorrect comparison width could cause the controller to miss the halt instruction.

Sign extension is not required for these register values because they are treated as unsigned control and data values. Truncating a 32-bit instruction or comparing only part of it could also produce incorrect results.

## U4 Computer organisation
The P57 Halt Controller mainly works during the instruction commit/control stage.

It detects the committed instruction `0x0000006F` (`j .`) and sets the HALT flip-flop. It can also set HALT when software writes to the HALT register.

The instruction comparator checks the instruction during commit. The controller does not perform normal instruction fetching, decoding, ALU execution or memory operations itself.

The `halted` output indicates that the processor must stop. Reset clears the HALT state.

The relevant instruction is `j .`, which encodes as `0x0000006F`. Software can also request a halt by writing to the HALT register.

## U5 Processors
The RC-V is a RISC-V processor and uses memory-mapped I/O to communicate with P57.

A CISC processor could perform the halt operation using a specialised I/O instruction rather than a normal memory-mapped store.

A stack machine would use stack-based operations and might need to push the halt value and device address before performing the I/O operation.

A GPU is designed for parallel processing and is not well suited to controlling a single processor halt signal. It would need to communicate with the control device through a command or memory-mapped interface.

The RC-V approach is simple because the processor uses ordinary load and store instructions to access I/O registers.

## U6 Memory and I/O
P57 is a memory-mapped I/O device. It does not directly access RAM during normal HALT operation.

The P57 device is connected through the I/O bus P33 and selected by the address decoder P31.

Its slot number is 15, with base address `0x000203C0`.

It has two registers:
- HALT register at `0x000203C0` (register 0).
- CODE register at `0x000203C4` (register 1).

The processor accesses these registers using ordinary load and store instructions. The I/O bus carries the address selection, read/write control signals and data. The `rdata` output returns the selected register value.

When the HALT condition is detected, P57 sets its `halted` output to signal the processor to stop.

## E1 Instruction trace: ADDI
Trace one **ADDI** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.


### E1 — Instruction trace: ADDI

I ran the P57 test program using the RC-V simulator with the `--trace` option. The trace completed in 53 cycles.

I examined the instruction `addi x5, x0, 10` at address `0x00000230`.

- **Fetch:** P14 provides the program counter and P30 reads the instruction from ROM.
- **Decode:** P17 extracts the instruction fields. P21 identifies the OP-IMM instruction class. P22/P23 generate the control signals, and P24 selects the appropriate control.
- **Immediate generation:** P18/P19 generate the immediate value 10, and P20 selects it.
- **Execute:** P26 selects the register and immediate operands. P10 controls the ALU, and P01–P08 perform the addition: 0 + 10 = 10.
- **Write-back:** P25 selects the result, and P11/P12 write the value 10 into register x5.
- **Next PC:** P03, P16 and P15 select the next instruction address.

The second instruction, `addi x6, x5, 3`, at address `0x00000234`, adds 3 to the value in x5 and writes 13 into x6.

The trace confirms:
- x5 = 0x0000000A
- x6 = 0x0000000D

ADDI does not need the data-memory access path because it uses a register and an immediate value rather than loading from or storing to memory.

## E2 Neighbour review
Review the pull requests of P56 (Instruction-mix counters) and P58 (Branch predictor (2-bit counters)). Paste the links to your review
comments here.

### E2 — Neighbour review

**P58 — Branch predictor (2-bit counters)**

Reviewed pull request #109 (`Update p58_bpred.v`). Checked the 16-counter structure, reset initialisation, prediction bit and saturating increment/decrement logic. Posted and submitted a review comment.

PR link: https://github.com/campus-sutra/rc-v/pull/109

**P56 — Instruction-mix counters**

Pending. The project pull request is not available yet. Review and add the review-comment link when it becomes available.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

### E3 — Where my block sits

P57 Halt Controller belongs to the I/O device layer of the RC-V SoC.

**Inputs:**
- P33 I/O bus provides the device interface signals, including `sel`, `we`, `re`, `ridx` and `wdata`.
- `commit` and `instr` provide the committed instruction information used to detect the halt instruction.
- `clk` and `rst` provide clock and reset.

**Outputs:**
- `rdata` returns the selected register value to the I/O bus.
- `halted` indicates that the processor should halt.

P57 is selected through the memory-mapped I/O address decoder P31 and communicates through the I/O bus P33.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 4).

- [ ] Logic gates, Boolean algebra, K-maps
- [ ] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [ ] Number systems, complements, signed arithmetic
- [ ] Bus organisation, instruction codes and formats
- [ ] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [ ] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA


### E4 — Syllabus map

- [✅] Combinational circuits and logic gates
- [✅] Flip-flops, registers and counters
- [ ] Karnaugh maps and Boolean simplification
- [✅] Number systems and binary/hexadecimal representation
- [ ] RAM and ROM design
- [✅] Bus organisation and instruction codes
- [✅] Instruction cycle and processor control
- [✅] RISC versus CISC
- [ ] Interrupts
- [ ] Pipelining
- [ ] Cache memory
- [✅] Memory-mapped I/O
