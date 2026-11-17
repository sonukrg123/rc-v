# P60 Parity generator - dossier

## U1 Digital logic
- XOR truth table: 00 -> 0, 01 -> 1, 10 -> 1, 11 -> 0. A xor B = A'B + AB'.
- XOR of many bits is 1 when the number of 1s is odd, so it gives parity.
- 15 XOR gates: 3 per byte (4-, 2-, 1-bit) plus 3 for the word parity. No flip-flops.

## U2 Digital components
- Splitters cut data into bytes; a merger packs the 5 parity bits.
- XOR gates compute parity. Three 3-bit Add blocks count the odd bytes.
- Const 0 widens each parity bit to 3 bits and feeds the carry-in.
- Verilog adds a 32-bit DATA register and a read multiplexer on `ridx`.

## U3 Data representation
- 13 = 0x0000000D: byte 0 has three 1s. parity = 17 (0b10001), odd = 1.
- 4294967295 = 0xFFFFFFFF (-1 signed): every byte even. parity = 0, odd = 0.
- 2879705167 = 0xABA4D04F: all four bytes odd. parity = 15 (0b01111), odd = 4.
- `odd` can reach 4 (100), so it needs 3 bits. Parity bits are zero-extended, not sign-extended.
- The program uses lbu, because I guess lb would sign-extend codes above 127.

## U4 Computer organisation
- Memory step: an I/O access through the address decoder (P31) and I/O bus (P33).
- Used by sw (write DATA at 0x00020480) and lw (read PARITY at 0x00020484).

## U5 Processors
- CISC (x86) has a parity flag and popcount; RV32I has neither, so it needs a shift/XOR loop or this device.
- A stack machine pushes bits and XORs the top two repeatedly.
- A GPU does the parity of many words in parallel.

## U6 Memory and I/O
- Memory-mapped I/O device, slot 18 at 0x00020480. The CPU uses ordinary loads and stores.
- Write: store data -> P27 -> P34 -> P31 -> P33 -> my device.
- Read: my device -> P32 -> P28 -> P25 -> register file.
- Programmed I/O, no interrupts. Register 15 reads 60 (the package number).

## E1 Instruction trace: XORI
Example: `xori x5, x6, 0x0F` = 0x00F34293, with x6 = 0x35 (hand-calculated).
- P14 PC and P30 ROM give the instruction.
- P17 fields: rd = 5, funct3 = 100, rs1 = 6, imm = 0x0F.
- P21 / P22 / P23 / P24: OP-IMM, control word 0x5000 (regwrite, bsel_imm).
- P18-P20: I-type immediate 0x0000000F. P13: x6 = 0x35.
- P26 picks the immediate as operand B. P10: funct3 100 = XOR.
- P08 ALU (with P01, P04-P07): 0x35 xor 0x0F = 0x3A.
- P25 selects the ALU result and writes 0x3A to x5. P03 / P15 / P14 give PC + 4.

## E2 Neighbour review
Review the pull requests of P59 (Pipeline hazard meter) and P61 (Text screen).
- P59 review: no pull request has been submitted yet. I will add my review when it is.
- P61 review:
- https://github.com/campus-sutra/rc-v/pull/147/changes/e241640c66a9968904c6ffe35b988a39b9578245#r4579138923
- https://github.com/campus-sutra/rc-v/pull/147/changes/e241640c66a9968904c6ffe35b988a39b9578245#r4579129840
- https://github.com/campus-sutra/rc-v/pull/146/changes/2cb580e657ee559c0a722952416c16e5316e29d2#r4579106575

## E3 Where my block sits
- It is in the I/O layer: a peripheral on the I/O bus, built from XOR gates, adders, a register and a multiplexer.
- I fed by the CPU's store data via P27, P34, P31, P33. Its output returns via P32, P28, P25 to the register file.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 2, Unit 3).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [ ] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
