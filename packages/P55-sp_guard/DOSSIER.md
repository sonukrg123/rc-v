# P55 Stack guard - dossier

## U1 Digital logic
The guard needs a "less than" test, so I looked at one bit of the comparator.

| A | B | A < B |
|---|---|-------|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 0 |
| 1 | 1 | 0 |

From the K-map: A < B = A'·B. For 8 bits, compare from the top bit down:
lt = lt7 + eq7·(lt6 + eq6·(...)), where eq = XNOR of the two bits.
The flag is `sp < limit`. The minimum is updated when `sp < minsp`. Storing
the result needs flip-flops (a register with an enable), because the guard has
to remember the lowest sp seen earlier.

## U2 Digital components
- Registers: `minsp` (8-bit) and the flag, both on `clk`, cleared by `rst` or `clear`.
- Comparator 1: `sp` against `limit`, gives `flag`.
- Comparator 2: `sp` against `minsp`; its output chooses between the new `sp`
  and the old `minsp` (a multiplexer).
- `sp_we` is the enable, so the registers only change when x2 is written.
- On reset or `clear`, `minsp` goes back to its maximum value (all ones),
  so the first sp written always becomes the new minimum.

## U3 Data representation
Three 8-bit test vectors, with limit = 0x40:

| sp (hex) | sp (binary) | sp (decimal) | Result |
|---|---|---|---|
| 0x50 | 0101 0000 | 80 | above limit, flag 0 |
| 0x30 | 0011 0000 | 48 | below limit (0x40 = 64), flag 1, minsp = 0x30 |
| 0x80 | 1000 0000 | 128 unsigned / -128 signed | above limit, flag 0 |

Problem case: 0x80 looks negative as a signed number. If I used a signed
comparator, -128 < 64 would wrongly raise the flag. Stack addresses are
unsigned, so the comparator must be unsigned. In the program, "remembered sp -
MINSP" is an unsigned subtraction with no overflow, because MINSP is never
above the starting sp.

## U4 Computer organisation
The block works at the write-back step (the Verilog watches `commit`, `rf_we`,
`rd == 2` and `rf_wd`). It also takes part in the memory step when software
does `lw` or `sw` to its registers. Instructions that matter: `addi sp, sp, -8`
at every call and `addi sp, sp, 8` at every return (they change x2), and `lw`/`sw`
to read LIMIT or MINSP and to write STATUS.

## U5 Processors
- CISC: PUSH, POP and CALL change the stack pointer by themselves, so the guard
  would watch one special stack-pointer register and not a normal write to x2.
- Stack machine: almost every instruction moves the stack pointer, so a limit
  check would sit directly in the hardware and run all the time.
- GPU: each thread has a small fixed private stack, so one guard per thread
  would be costly. Overflow is usually prevented by limiting the call depth.

## U6 Memory and I/O
The guard is a memory-mapped I/O device in slot 13 (registers from 0x00020340).
The address decoder makes `sel` high for that range. A `sw` sets `we` and puts
the data on `wdata`; a `lw` sets `re` and the value comes out on `rdata`,
which reaches the CPU through the I/O read bus. `irq` equals STATUS bit 0 and
goes to the interrupt controller. Register 15 reads 55 to identify the device.

## E1 Instruction trace: SB
Instruction: `sb x6, 3(x5)` with x5 = 0x00000100 and x6 = 0x000000AB.
Encoding: 0x006281A3.

| Block | What happens | Main signals |
|---|---|---|
| PC register / PC incrementer | PC supplies the address, PC + 4 is the next PC | next PC = PC + 4 |
| Instruction field splitter | splits the word into fields | opcode 0100011, funct3 000, rs1 = 5, rs2 = 6 |
| Opcode class / control unit | recognises a store, so memory write on and no register write | mem_we = 1, rf_we = 0 |
| Immediate generator (I/S) | joins imm[11:5] and imm[4:0] | imm = 3 |
| Register-file read port | reads both registers | rs1 = 0x100, rs2 = 0xAB |
| ALU operand selector + adder | adds base register and immediate | address = 0x103 |
| Store aligner | byte lane chosen by address[1:0] = 3 | data = 0xAB in lane 3, byte enable 1000 |
| Address decoder | address 0x103 is data memory, not I/O | memory selected |
| Data memory | only byte 0x103 changes | write |
| Write-back | nothing written (rf_we = 0) | - |

(Replace the values with the ones from the simulator's `--trace` output if
you run it.)

## E2 Neighbour review
- P54: no pull request has been submitted yet. I will add my review when it is.
- P56: no pull request has been submitted yet. I will add my review when it is.

## E3 Where my block sits
My block is in the I/O layer, as a memory-mapped device that watches the datapath.
It is fed by the register-file write port (`commit`, `rf_we`, `rd`, `rf_wd`) and
by the address decoder and store path (`sel`, `we`, `wdata`). Its output goes
to the I/O read bus (`rdata`) and to the interrupt controller (`irq`).

## E4 Syllabus map
- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [ ] Instruction cycle, hardwired vs microprogrammed control
- [x] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
