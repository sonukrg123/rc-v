# P37 Control and status registers - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic

I picked the **MPIE flip-flop** ("the old interrupt-enable setting"). On every clock tick it decides what to store next. The decision has a fixed priority: reset first, then trap, then mret, otherwise keep the old value.

| rst | trap | mret | MPIE next |
|-----|------|------|-----------|
| 1   | x    | x    | 0         |
| 0   | 1    | x    | MIE (copy the current interrupt-enable) |
| 0   | 0    | 1    | 1         |
| 0   | 0    | 0    | MPIE (hold) |

(x = don't care, because a higher-priority row already decided.)

Boolean expression:

MPIE⁺ = ¬rst · [ trap · MIE + ¬trap · ( mret + MPIE ) ]

Check: if mret = 0 the inner part gives MPIE (hold); if mret = 1 it gives 1.

MIE follows the same idea: MIE⁺ = ¬rst · ¬trap · [ mret · MPIE + ¬mret · ( set_mie + MIE ) ]. A trap clears it, mret restores it from MPIE, and set_mie turns it on.

I built these with **multiplexers** in Digital (one mux per priority level) instead of drawing separate AND/OR gates. The mux chain does the same job as the expression above. The flip-flops needed: one D flip-flop for MPIE, one for MIE, and one 8-bit D flip-flop for mtvec.

## U2 Digital components

My Digital circuit uses:
- **3 D flip-flops (registers):** `mtvec` (8 bits wide), `mie` (1 bit), `mpie` (1 bit). They hold their value until the clock ticks.
- **11 multiplexers:** 4 eight-bit ones feed `mtvec`, 3 one-bit ones feed `mpie`, 4 one-bit ones feed `mie`. Each chain is a priority list: the first mux checks reset, the next checks trap, the next mret, and so on. The last mux in each chain feeds the flip-flop's input.
- **Constants:** fixed 0s and 1s, e.g. "MIE becomes 0 on a trap", "MPIE becomes 1 on mret", "reset makes mtvec 0".
- **Clock and input/output pins:** `clk, rst, we, wdata, trap, mret, set_mie` in; `mtvec, mie, mpie` out.

No adders, decoders or memory are needed, because the block only stores a few values and picks which one to store.

## U3 Data representation

Three test vectors from my public tests (wdata is written into the 8-bit mtvec):

| wdata decimal | binary | hex | meaning |
|---|---|---|---|
| 26  | 0001 1010 | 0x1A | unsigned 26; mtvec becomes 26 |
| 128 | 1000 0000 | 0x80 | unsigned 128, but **signed 8-bit it would be -128** |
| 255 | 1111 1111 | 0xFF | unsigned 255, but **signed 8-bit it would be -1** |

Two more examples from the full block:
- The program writes -42 into `mscratch`. In 32 bits that is 1111 1111 1111 1111 1111 1111 1101 0110 = **0xFFFFFFD6**. Printed as a signed number it is -42 again.
- `mstatus` read value with MIE = 1 and MPIE = 1: bit 3 and bit 7 are set = 1000 1000 = **0x88** = 136 decimal.

Where it could go wrong: `mtvec` and `mepc` are **addresses**, so they must be treated as unsigned. If someone sign-extended 0x80 or 0xFF to 32 bits it would turn into a huge address like 0xFFFFFF80. The stored value is never added to anything inside my block, so overflow cannot happen here. But a wrong bit position in `mstatus` (bit 3 for MIE, bit 7 for MPIE) would silently turn interrupts on or off.

## U4 Computer organisation

My block does its work in the **interrupt step** of the instruction cycle, plus the execute/write-back step for CSR instructions.
- **Interrupt/trap:** when a trap happens, the processor does not run the instruction. My block saves the PC in `mepc`, the reason in `mcause`, copies MIE to MPIE and clears MIE. The next PC then comes from `mtvec`.
- **mret:** restores MIE from MPIE, sets MPIE to 1, and the next PC comes from `mepc`.
- **CSR instructions:** `csrw`/`csrr` (CSRRW/CSRRS) read or write a register in my block. In the control word the SYSTEM opcode sets `is_csr`, and write-back selects the CSR value (wbsel = 3).

Instructions that need my block: `csrrw`, `csrrs`, `csrrc` (and the pseudo-instructions `csrw`, `csrr`), `mret`, `ecall` (mcause 11), an illegal instruction (mcause 2), and any enabled interrupt.

## U5 Processors

- **CISC (e.g. x86):** on an interrupt the hardware itself pushes the flags and return address onto the stack in memory and looks up the handler in a table, then a special return instruction pops them. That is several memory accesses. RISC-V instead keeps the saved state in a few named registers (`mepc`, `mstatus`), so a trap takes no memory traffic and my block is just a small register file.
- **Stack machine:** there are no named general registers. The return address would be pushed on the stack, so a "mepc" register is not needed; the stack top plays that role.
- **GPU:** a GPU runs thousands of threads in lockstep, so it does not save and restore one program counter per thread the way my block does. Traps and interrupts are mostly handled for the whole group or by the host CPU.
- **Mano's Basic Computer** (from docs/ARCHITECTURE.md) is the closest comparison: its interrupt cycle puts PC in M[0] and clears IEN. RC-V puts PC in `mepc` and clears MIE, a register instead of a memory cell.

## U6 Memory and I/O

My block does **not** read or write RAM or I/O itself. CSRs have their own 12-bit address space (e.g. 0x300 mstatus, 0x340 mscratch) that is separate from the memory map (ROM at 0x0000_0000, RAM at 0x0001_0000, I/O at 0x0002_0000).

Neighbours that do the memory and I/O work: the address decoder (P31), RAM (P29) and the I/O bus (P33). The data reaches my block through the CSR instruction path: the value to write comes from a register (through P38, the CSR read-modify-write block) into `wdata`, and `rdata` goes back through write-back (wbsel = 3) into the destination register.

I do take part in I/O indirectly: when a device raises an interrupt (the interrupt controller P47), my block saves the PC and disables interrupts so the handler can run. `mscratch` also gives the handler a safe place to park one value without touching memory.

## E1 Instruction trace: MRET

**Encoding:** MRET = `0x30200073`. Fields: opcode `1110011` (SYSTEM), rd = 0, funct3 = 000, rs1 = 0, imm = `0x302`.

Path through the processor (single clock):

| Step | Block | What happens / signal |
|---|---|---|
| Fetch | P14 PC, P30 ROM | PC points at the MRET word; ROM outputs `0x30200073`. P03 computes PC+4 (not used here). |
| Decode | P17 fields, P21 class decoder | opcode `1110011` = SYSTEM class. |
| Control | P22 / P23, P24 | control word for SYSTEM = `0x4181` (`is_csr` = 1, `regwrite` = 1, `wbsel` = 3). rd = x0, so nothing is actually changed in a register. |
| Trap/CSR logic | P39 trap decision, P37 CSR file | the MRET word is recognised and `mret` = 1 is sent to my CSR file. |
| Execute | P37 | **MIE ← MPIE, MPIE ← 1.** |
| Next PC | P16 next-PC logic, P15 next PC | PC ← `mepc` (the saved PC from the trap). |
| Memory | none | no load or store. |
| Write back | P25 | nothing useful written (rd = x0). |

Example values (illustrative; a trap hit at PC 0x40 with interrupts on):
- before MRET: `mepc` = 0x00000040, MIE = 0, MPIE = 1, PC = (somewhere in the handler)
- after MRET: **PC = 0x00000040**, MIE = 1, MPIE = 1

## E2 Neighbour review

To Review the pull requests of P40 (Illegal-instruction detector) and P38 (CSR read-modify-write).

## E3 Where my block sits

My block sits in the **control** layer (the traps and interrupts group): it stores the processor's trap state. It is fed by the PC (P14), the trap decision logic (P39, which also gets the illegal-instruction signal from P40 and the interrupts from P47) and the CSR instruction path (P38). Its outputs are used by the next-PC logic (P15/P16, through `mtvec` and `mepc`), the trap decision (the `mie` bit) and the write-back path (`rdata` for `csrr`).

## E4 Syllabus map

Tick every syllabus topic your work touched (main units: Unit 4, Unit 6).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
