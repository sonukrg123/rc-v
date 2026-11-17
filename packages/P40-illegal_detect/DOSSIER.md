# P40 Illegal-instruction detector - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

The trickiest part is the OP-IMM group (opcode 0010011). Most of its instructions (addi, andi, ...) are
always legal, but the shifts check funct7: slli needs funct7 = 0000000, srli/srai need 0000000 or 0100000.
Let `s1` = (funct3 == 001), `s5` = (funct3 == 101), `z` = (funct7 == 0), `m` = (funct7 == 0100000).

| s1 | s5 | z | m | legal (OP-IMM) |
|---|---|---|---|---|
| 0 | 0 | x | x | 1 (not a shift) |
| 1 | 0 | 1 | x | 1 (slli) |
| 1 | 0 | 0 | x | 0 |
| 0 | 1 | 1 | x | 1 (srli) |
| 0 | 1 | 0 | 1 | 1 (srai) |
| 0 | 1 | 0 | 0 | 0 |

Expression: `ok_imm = op_imm . ( NOT(s1 + s5) + s1.z + s5.(z + m) )`.
At the top, `legal` is the OR of ten "this instruction class is fine" signals and `illegal = NOT legal`.
I only needed AND and OR gates; NOT is made from a 1-bit comparator ("= 0"). There are no flip-flops
because the block is purely combinational.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

One Splitter cuts the 32-bit `instr` into opcode (bits 6-0), funct3 (14-12), funct7 (31-25) and a 2-bit
piece of funct3. Then 24 Comparators with Const inputs act as equality decoders: ten for the opcodes,
six for funct3 values, two for funct7 (0 and 0x20), one 2-bit one for the branch rule, two 32-bit ones for the
exact words ECALL (0x00000073) and MRET (0x30200073), and three small ones used as NOT. Their "=" outputs are
combined with 10 AND and 22 OR gates into `legal`, and the last comparator inverts it to `illegal`. Signals are
joined with Tunnels (names like `o_jalr`, `f3_0`, `ok_ld`). There are no adders, multiplexers, registers or memory.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

| instr (hex) | binary | decimal | result |
|---|---|---|---|
| 0x00351513 | 0000 0000 0011 0101 0001 0101 0001 0011 | 3478803 | legal: opcode 0010011, funct3 001, funct7 0 = `slli a0,a0,3` |
| 0x00005003 | 0000 0000 0000 0000 0101 0000 0000 0011 | 20483 | illegal: LOAD with funct3 101 = `lhu`, not in RC-V |
| 0xFFFFFFFF | 1111 1111 ... 1111 | 4294967295 unsigned, -1 signed | illegal: opcode 1111111 does not exist |

The block does no arithmetic, so there is no overflow. The risk is the sign: bit 31 is the top bit of funct7, so a
signed comparison would see 0xFFFFFFFF as -1 and 0x30200073 as the wrong number. My comparators are unsigned and I
compare the fields (not sign-extended values), so this is safe. In Verilog I use unsigned wires for the same reason.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

It works in the decode step: as soon as the instruction word arrives from ROM, `illegal` is computed in
parallel with the control unit. If it is 1, the instruction is not executed and the interrupt/trap step
happens instead (mepc = PC, mcause = 2, PC = mtvec). Every instruction needs the check, because
the processor cannot know in advance which word is bad, but only unknown encodings (like 0x00000000, lhu,
mul or csrrwi) ever raise it.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

RC-V has fixed 32-bit instructions, so one combinational look at the opcode, funct3 and funct7 is enough. A CISC
processor has variable-length instructions with prefixes and many addressing modes, so its decoder first has to find
the length and then check a much larger table (often with a microcode ROM), and "undefined opcode" is harder to
decide. A stack machine has few opcodes with no register fields, so its check is a small table lookup on one byte.
A GPU decodes one instruction for many threads at once and traps per warp, not per thread. Mano's Basic Computer
has only 3 opcode bits plus the I bit, so almost every word is legal and it has no illegal-instruction trap.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

It does not take part in any memory access or I/O transfer; it only reads `instr` and drives one wire. The
neighbouring blocks do the transfers: ROM (P30) provides the instruction, and for loads and stores the bus arbiter (P34),
address decoder (P31) and I/O bus (P33) move the data. My program does use I/O: the handler prints through the
library routines, which write the characters to the terminal's TXDATA register with SW (memory-mapped I/O).

## E1 Instruction trace: SW to the terminal
Trace one **SW to the terminal** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

I ran `li t0, UART_TXDATA; li t1, 'A'; sw t1, 0(t0)` on the simulator with --trace. Before the store the trace shows
x5 = 0x00020000 and x6 = 0x00000041. The store is `0x0062a023` (`sw t1, 0(t0)`: opcode 0100011, funct3 010, rs1 = x5, rs2 = x6, imm = 0).

1. Fetch: PC (P14) addresses ROM (P30), which returns `0x0062a023`.
2. Decode: fields (P17) give rs1 = 5, rs2 = 6; class decoder (P21) says STORE; control word `0x1210` from P22/P23 through P24: memwrite = 1, bsel_imm = 1, immsel = S, regwrite = 0. My P40 block also sees this word and says `illegal = 0` (funct3 010 is `sw`, allowed).
3. Immediate: the S-type immediate (P19) is 0, chosen by P20. Register file (P13) reads x5 = 0x00020000 and x6 = 0x00000041.
4. Execute: operand select (P26) picks the immediate as B; the ALU adds 0x00020000 + 0 = 0x00020000 (the address).
5. Memory: store align (P27) places the data 0x00000041; bus arbiter (P34) passes it on; the address decoder (P31) sees 0x0002_0000 = I/O area, slot 0 = terminal; the I/O bus (P33) selects the terminal (P41), and at the clock edge (`sel & we`) the TXDATA register takes 0x41, so the letter A appears on the terminal.
6. Write-back: nothing, because regwrite = 0. Next PC: PC + 4 (P03) goes through P16 and P15 back to PC.

## E2 Neighbour review
Review the pull requests of P39 (Trap controller) and P37 (Control and status registers). Paste the links to your review
comments here.

My review partners P39 (Trap controller) and P37 (Control and status registers) have not submitted their
pull requests yet, so there is nothing to review at the moment. I will review both as soon as their pull requests
are open and will add the links to my review comments here.

What I will check, because my block P40 feeds them: in P39, `illegal` must give mcause 2 and the trap must win over
a normal instruction; in P37, mepc must hold the address of the bad instruction.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

It is in the control layer (decode side), built from gates and comparators. It is fed only by the instruction
word `instr` coming from ROM (P30). Its output `illegal` goes to the trap controller (P39), which sets `trap` and
`cause`; P37 then stores mepc and mcause and the next-PC logic jumps to mtvec.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 4, Unit 5).

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