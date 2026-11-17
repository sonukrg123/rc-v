# P39 Trap controller - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
My block is combinational. It has six inputs (`stall`, `irq`, `mie`, `illegal`, `is_ecall`, and the 5-bit `irq_cause`) and decides one output bit, `trap`. The truth table below shows the main cases (X = don't care):

| stall | irq | mie | illegal | is_ecall | trap | reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | X | X | X | X | 0 | stalled: never trap |
| 0 | 1 | 1 | X | X | 1 | enabled interrupt |
| 0 | 1 | 0 | 0 | 0 | 0 | interrupt masked, nothing else |
| 0 | X | X | 1 | X | 1 | illegal instruction |
| 0 | X | X | 0 | 1 | 1 | ECALL |
| 0 | 0 | X | 0 | 0 | 0 | nothing to do |

Simplified expression:

`trap = NOT(stall) AND ((irq AND mie) OR illegal OR is_ecall)`

I needed only three gate types: NOT, AND and OR. No flip-flops, because the block has no memory. The state (`mie`, `mepc`, `mcause`) lives in the CSRs, not in my block.

The priority (interrupt, then illegal, then ECALL) only matters for `cause`, not for `trap`, so it does not change the expression above.

## U2 Digital components
My Digital circuit has two halves.

Top half (decides `trap`): one NOT gate makes `no_stall`. A 3-input AND (`no_stall`, `irq`, `mie`) gives `ei`, the enabled interrupt. A NOT of `ei` and an AND with `no_stall` give `go`, which means "nothing of higher priority is active". `il` = `go` AND `illegal`, and `ec` = `go` AND `is_ecall` AND NOT `illegal`. A 3-input OR of `ei`, `il` and `ec` gives `trap`.

Bottom half (builds `cause`): a splitter widens the 5-bit `irq_cause` to 32 bits by adding 27 zero bits. An adder computes `0x80000010 + irq_cause` (carry-in tied to 0). Three 32-bit multiplexers in a chain pick the answer: the first chooses 11 (if `ec`) or 0, the second chooses 2 (if `il`) or the previous result, and the third chooses the adder result (if `ei`) or the previous result. Constants supply 0, 2, 11 and 0x80000010. Tunnels join wires with the same name.

Because `il` and `ec` already include "not stalled", a stalled cycle falls all the way through the chain to 0, so `cause` is exactly 0 whenever there is no trap.

## U3 Data representation
Three test vectors (all with `stall` = 0):

| Test | Inputs | `cause` binary | hex | decimal |
| --- | --- | --- | --- | --- |
| Software interrupt | irq=1, mie=1, irq_cause=4 (0b00100) | 1000 0000 0000 0000 0000 0000 0001 0100 | 0x80000014 | 2,147,483,668 unsigned, -2,147,483,628 signed |
| Illegal instruction | illegal=1, no enabled interrupt | 0000 ... 0000 0010 | 0x00000002 | 2 |
| ECALL | is_ecall=1, nothing else | 0000 ... 0000 1011 | 0x0000000B | 11 |

Bit 31 of `cause` is the "this is an interrupt" flag. That is why the interrupt value looks negative if it is read as a signed number: it is the same bits, only the reading is different. The checker and `mcause` treat it as an unsigned flag plus a code.

Where it could go wrong: `irq_cause` is only 5 bits, so it must be zero-extended to 32 bits before the addition. If it were sign-extended, a value with bit 4 set (16 to 31) would turn into a negative number and the cause would be wrong. Overflow is not a problem: the largest result is 0x10 + 31 = 47 = 0x2F, so it carries into bit 5 but never reaches bit 31. The result for the software interrupt is only correct because bit 31 stays set and the low bits are added without any carry out of the 32-bit word.

## U4 Computer organisation
My block works in the **interrupt check** step of the instruction cycle (P47, P39, P37 in the architecture table), in the same clock as fetch-decode-execute. Every cycle it looks at the signals and decides whether the current instruction runs at all. If `trap` is 1, the instruction is not executed. The hardware then saves the PC in `mepc`, writes `cause` to `mcause`, copies `MIE` into `MPIE`, clears `MIE`, and loads the PC with `mtvec`.

Instructions and events that need it: `ECALL` (cause 11), any illegal instruction word (cause 2), and any instruction that gets interrupted by a device (cause 0x80000010 + source). `MRET` is the way back: it sets PC = `mepc`, `MIE` = `MPIE` and `MPIE` = 1. My program `p39.s` uses the software interrupt: it writes 1 to `IRQ_SWI`, the trap is taken before the next instruction, and the handler returns with `mret`.

## U5 Processors
RISC-V (RC-V): the return address is saved in a special register, `mepc`, and the reason in `mcause`, so the trap entry needs no memory access and the handler is a normal piece of code that ends with `mret`.

Mano's basic computer (accumulator machine, 16-bit): it has one interrupt enable flip-flop (IEN) and one request flip-flop (R). In its interrupt cycle it does M[0] <- PC, PC <- 1, IEN <- 0, so the return address goes to memory; in RC-V the trap does mepc <- PC, PC <- mtvec, MIE <- 0, with no memory access. There is no cause register, so the handler must poll the devices to find out who asked.

A stack machine: it would push the PC and the status flags on the stack and pop them on return. That needs a memory write on every trap and the stack pointer must always be valid, but there is no need for special registers like `mepc`.

A GPU: many threads run in lock step, so it normally does not give precise per-thread interrupts. Errors and requests are usually handled at kernel or warp level by the host CPU, so a trap controller like mine would sit on the CPU side, not inside each GPU thread.

A CISC processor with complex instructions (for example one that can take several cycles and many memory accesses) must also remember how far an instruction got, so it needs more state than RC-V to restart or continue it.

## U6 Memory and I/O
My block does not move data and does not touch memory. It only decides whether to trap. The neighbouring block that takes part in I/O is the interrupt controller: it holds the registers PENDING, MASK, CAUSE and SWI, and it raises the `irq` and `irq_cause` signals that come into my block.

My program talks to it with memory-mapped I/O: ordinary `sw` stores to `IRQ_MASK` (to allow source 4) and to `IRQ_SWI` (to raise the software interrupt, and to clear it again in the handler). When an interrupt is allowed (`mie` = 1), my block turns the request into a trap and the processor runs the handler. This is **interrupt-driven I/O**: the processor does not wait in a loop asking the device, the device interrupts the processor when it needs attention.

## E1 Instruction trace: LW from an I/O device
Example instruction: `lw a0, 0(t1)`, where `t1` = `0x00020040` is the address of device slot 1 (the keyboard, package P42), register 0 (RXDATA). Machine word: `0x00032503` = imm 0, rs1 = x6 (t1), funct3 = 010, rd = x10 (a0), opcode = 0000011 (LOAD). RC-V is single-cycle, so all of this happens in one clock.

| Step | Block | What happens, with the main values |
| --- | --- | --- |
| Fetch | P14 PC, P30 ROM, P03 (+4) | The PC addresses the ROM and the word `0x00032503` comes out. P03 computes PC + 4. |
| Decode | P17 fields | rs1 = 6, rd = 10, funct3 = 010, opcode = 0000011. |
| Decode | P21 class decoder, P22 hardwired control (P23 control ROM gives the same word), P24 select/check | Class LOAD, control word `0x5480`: regwrite = 1, bsel_imm = 1, memread = 1, wbsel = 01 (memory), immsel = 0 (I-type). P24 raises no `mismatch`. |
| Decode | P18, P19, P20 immediates | I-type immediate = 0. |
| Decode | P11, P12, P13 register file | Reads t1: rs1 value = `0x00020040`. |
| Execute | P26 operand select, P10 ALU control, P08 ALU (with P01, P04-P07) | A = rs1, B = immediate 0, operation ADD. Result = `0x00020040`, the effective address. |
| Memory | P34 bus arbiter | Passes the address (no DMA is stealing this cycle). |
| Memory | P31 address decoder | `0x00020040` lies in 0x0002_0000 - 0x0002_07FF, so it is the I/O region, not RAM or ROM. |
| Memory | P33 I/O bus | Slot = (0x40 - 0x00) / 64 = 1, register 0: keyboard (P42) RXDATA. `sel` and `re` are raised. A read with side effect (it removes the key from the buffer) takes effect at the clock edge. |
| Memory | P32 read select | Chooses the I/O data as the memory result (not RAM, not ROM). |
| Memory | P28 load extend | LW takes the whole 32-bit word, so nothing is sign- or zero-extended. |
| Write back | P25 write-back, P11/P12 | wbsel = 01 chooses the memory value, which is written into a0 (x10). Example: a typed `A` gives `a0` = `0x00000041`. |
| Next PC | P16 next-PC logic, P15 next PC | No branch and no trap, so the next PC = PC + 4. |
| Interrupt check | P47, P39, P37 | In the same cycle my block gets `stall` = 0, `irq` = 0 (or `mie` = 0), `illegal` = 0, `is_ecall` = 0. So `trap` = 0 and `cause` = 0, and the instruction completes normally. |

The values for the PC and for the character are examples; the structure comes from `docs/ARCHITECTURE.md`. `rcv-sim --trace` prints the real PC, the instruction word and the register change for this instruction.

## E2 Neighbour review
Review links for P38 (CSR read-modify-write) and P40 (Illegal-instruction detector):

- P38 review comment: TODO (paste the link after reviewing)
- P40 review comment: TODO (paste the link after reviewing)

## E3 Where my block sits
My block is in the **control layer**: it is the gatekeeper of the interrupt cycle. It is fed by the interrupt controller P47 (`irq`, `irq_cause`), the CSRs P37 (`mie`, from mstatus.MIE), the illegal-instruction detector P40 (`illegal`), the instruction decoder (`is_ecall`) and the stall signal (the DMA controller can steal cycles). Its outputs, `trap` and `cause`, go to the next-PC logic P16/P15 (to jump to `mtvec`) and to the CSRs P37 (to write `mepc` and `mcause`).

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 4).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
