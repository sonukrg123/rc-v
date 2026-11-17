# P25 Write-back selector - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

The P25 write-back selector uses a 2-bit control input (`wbsel`) to select one of four 4-bit data inputs.


### Answer
**Truth table:**

| wbsel[1] | wbsel[0] | S0 | S1 | S2 | S3 | Selected input |
|---|---|---|---|---|---|---|
| 0 | 0 | 1 | 0 | 0 | 0 | alu_y |
| 0 | 1 | 0 | 1 | 0 | 0 | mem_val |
| 1 | 0 | 0 | 0 | 1 | 0 | pc4 |
| 1 | 1 | 0 | 0 | 0 | 1 | csr_rd |

**Boolean expressions:**

Let `b1 = wbsel[1]` and `b0 = wbsel[0]`.

- S0 = NOT b1 AND NOT b0
- S1 = NOT b1 AND b0
- S2 = b1 AND NOT b0
- S3 = b1 AND b0

For each output bit `i`, the simplified selection expression is:

`wd[i] = (alu_y[i] AND S0) OR (mem_val[i] AND S1) OR (pc4[i] AND S2) OR (csr_rd[i] AND S3)`

**Gates and components used:**

- NOT gates generate the complemented control signals.
- AND gates decode `wbsel` and gate the individual data bits.
- OR gates combine the four selected data sources for each output bit.
- Splitters and a merger separate and combine the 4-bit data buses.
- Tunnels are used to organise connections.

No flip-flops are required because P25 is a combinational circuit. Its output depends only on the current inputs.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

### Answer
The P25 Digital circuit is a 4-bit combinational write-back selector built using basic logic gates.

**Building blocks used:**

1. **Splitters:** Four splitters separate the four 4-bit data inputs (`alu_y`, `mem_val`, `pc4`, and `csr_rd`) into individual bits.
2. **Decoder:** NOT and AND gates decode the 2-bit `wbsel` input into four selection signals (S0, S1, S2 and S3).
3. **AND gates:** Each data bit is ANDed with its corresponding selection signal. This allows only the selected input data to pass through.
4. **OR gates:** The corresponding bits from the four data sources are combined using OR gates to generate the four output bits.
5. **Merger:** A 4-bit merger combines the output bits into the final `wd` output.
6. **Tunnels:** Tunnels help organise connections and avoid unnecessary wire crossings.

**Connection and operation:**

The `wbsel` input is connected to the decoder. The decoder generates one active selection signal out of four. Each selection signal controls the AND gates connected to its corresponding data input. The OR gates combine the selected data bits, and the merger produces the final 4-bit `wd` output.

The circuit does not use a dedicated Multiplexer component, adder, register, or memory. Instead, the multiplexer function is implemented using a decoder and an AND-OR gate network. It is a combinational circuit, so no flip-flops are needed.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

### Answer
#### Three test vectors

The P25 Digital circuit uses 4-bit data inputs and a 2-bit write-back selector. The following examples are taken from the supplied public test vectors.

| Test | wbsel | alu_y | mem_val | pc4 | csr_rd | wd |
|---|---|---|---|---|---|---|
| 1 (Decimal) | 0 | 15 | 15 | 15 | 4 | 15 |
| 2 (Decimal) | 1 | 9 | 9 | 11 | 11 | 9 |
| 3 (Decimal) | 2 | 0 | 7 | 4 | 0 | 4 |

**Binary representation:**

| Test | wbsel | alu_y | mem_val | pc4 | csr_rd | wd |
|---|---|---|---|---|---|---|
| 1 | 00 | 1111 | 1111 | 1111 | 0100 | 1111 |
| 2 | 01 | 1001 | 1001 | 1011 | 1011 | 1001 |
| 3 | 10 | 0000 | 0111 | 0100 | 0000 | 0100 |

**Hexadecimal representation:**

| Test | wbsel | alu_y | mem_val | pc4 | csr_rd | wd |
|---|---|---|---|---|---|---|
| 1 | 0 | F | F | F | 4 | F |
| 2 | 1 | 9 | 9 | B | B | 9 |
| 3 | 2 | 0 | 7 | 4 | 0 | 4 |

**Explanation:**

- Test 1: `wbsel = 00` selects `alu_y`. The output is `1111` (hex F, decimal 15).
- Test 2: `wbsel = 01` selects `mem_val`. The output is `1001` (hex 9, decimal 9).
- Test 3: `wbsel = 10` selects `pc4`. The output is `0100` (hex 4, decimal 4).

**Signed representation:**

In 4-bit two's complement, `1111` represents -1 and `1001` represents -7. When interpreted as unsigned values, they represent 15 and 9 respectively. P25 does not perform signed or unsigned arithmetic; it simply passes the selected bit pattern unchanged.

**Overflow and sign extension:**

P25 itself does not perform arithmetic, so arithmetic overflow must be handled by the upstream ALU. The 4-bit Digital model cannot preserve values wider than four bits; truncating upper bits would produce an incorrect result.

For load instructions, sign extension or zero extension must be performed by the P28 load extender before the value reaches P25. For example, an 8-bit value `0x80` should become `0xFFFFFF80` when sign-extended, or `0x00000080` when zero-extended. P25 must pass the correctly extended 32-bit value without changing it.

The remaining selector value `wbsel = 11` selects `csr_rd` and is also covered by the supplied test suite.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

### Answer
The P25 write-back selector performs its work during the **write-back stage** of the instruction cycle.

RC-V is a single-cycle 32-bit RISC-V processor. In each clock cycle, an instruction passes through fetch, decode, execute, memory access (if required), and write-back.

P25 selects the correct value to be written into the destination register (`rd`). It uses the 2-bit `wbsel` control signal to select one of four sources:

| wbsel | Selected source | Instructions |
|---|---|---|
| 00 | ALU result | ADD, SUB, logical and other ALU instructions, LUI, AUIPC |
| 01 | Memory value | Load instructions such as LW, LB and LBU |
| 10 | PC + 4 | JAL and JALR |
| 11 | CSR read value | CSR instructions that write a destination register |

The selected value is sent to the register file through the write-back datapath.

Store instructions and conditional branches do not normally need P25 because they do not write a result to a destination register. P25 is therefore an important part of completing instructions that produce a value for `rd`.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

### Answer
The P25 write-back selector in RC-V is part of a RISC-V register-based datapath. It selects one of four sources (ALU result, memory value, PC+4 or CSR value) and sends the selected value to the destination register.

**1. CISC processor:**

A CISC processor can execute more complex instructions, which may involve multiple internal operations. Its control unit coordinates the required operations and selects the appropriate result for the destination. The write-back selection may be integrated into a more complex datapath rather than using a separate simple selector like P25.

**2. Stack machine:**

A stack machine uses a stack instead of explicitly named general-purpose registers for most operations. The ALU takes operands from the top of the stack and pushes the result back onto it. Therefore, the result would normally be written to the stack rather than selected for a destination register such as `rd`.

**3. GPU:**

A GPU performs many operations in parallel across multiple processing lanes. Each lane may need to select its own result from sources such as an ALU operation or a memory load. The write-back selection is therefore replicated or organised across multiple lanes instead of serving only one scalar datapath.

**Conclusion:**

Different processor architectures organise result selection according to their datapath and register organisation. RC-V uses a simple 2-bit selector to choose one of four sources for register write-back.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

### Answer
The P25 write-back selector does not directly access memory or perform I/O operations. Instead, it selects the data returned by neighbouring blocks and forwards it to the register file.

**Memory load operation:**

1. The ALU (P08) calculates the memory address.
2. The bus arbiter (P34) and address decoder (P31) route the request to the appropriate memory device.
3. RAM (P29) provides the requested data.
4. The read selector (P32) selects the data from RAM, ROM or the I/O bus.
5. The load extender (P28) performs sign extension or zero extension when required.
6. P25 selects the memory value using `wbsel = 01` and sends it to the register file (P11/P12).

**I/O read operation:**

The I/O bus (P33) provides data from an I/O device. This data passes through the read selector (P32) and load extender (P28), then reaches P25. P25 selects the memory/I/O value and forwards it to the destination register.

**Store operation:**

For a store instruction, data travels from the register file through the store aligner (P27), bus arbiter (P34) and address decoder (P31) to RAM or an I/O device. P25 is not involved because store instructions do not write a result into a destination register.

Therefore, P25 acts as the final data selector in the write-back path, rather than being a memory or I/O controller.

## E1 Instruction trace: ADD
### ADD instruction trace

I traced an ADD instruction through the RC-V processor using the simulator's `--trace` option.

**Test program:**

```asm
li  t0, 7
li  t1, 5
add t2, t0, t1
ret
```

The ADD instruction is:

```asm
add t2, t0, t1
```

It performs:

`t2 = t0 + t1 = 7 + 5 = 12`

**Actual simulator trace:**

The following lines are taken from the simulator output:

```text
51  00000230  00700293  x5=0x00000007
53  00000238  00500313  x6=0x00000005
55  00000240  006283b3  x7=0x0000000c
56  00000244  00008067
```

The first two instructions initialise the source registers. The ADD instruction at PC `0x00000240` writes the result `0x0000000c` (12) into x7. The following instruction at PC `0x00000244` is `ret`.

**Instruction decoding:**

| Field | Value |
|---|---|
| PC | `0x00000240` |
| Machine code | `0x006283b3` |
| Opcode | `0110011` |
| rs1 | x5 |
| rs2 | x6 |
| rd | x7 |
| funct3 | `000` |
| funct7 | `0000000` |
| Operation | ADD |

**Processor blocks and main signal values:**

| Stage | Blocks | Operation and values |
|---|---|---|
| Fetch | P14, P30 | P14 provides PC = `0x240`. P30 fetches instruction `0x006283b3` from ROM. |
| Decode | P17, P21, P22, P23, P24 | P17 extracts the instruction fields. P21 identifies the OP instruction class. P22 and P23 produce the control word `0x4000`. P24 selects the control source and checks for disagreement. |
| Register read | P11, P12, P13 | The register file provides rs1 = x5 = 7 and rs2 = x6 = 5. |
| Operand selection | P26 | Since `asel_pc = 0` and `bsel_imm = 0`, P26 selects the two register operands: 7 and 5. |
| Execute | P10, P01–P08 | P10 selects the ADD operation. P08 ALU calculates `7 + 5 = 12`. |
| Memory | P27, P34, P31, P29, P33, P32, P28 | No data-memory or I/O access is needed. `memread = 0` and `memwrite = 0`. |
| Write-back | P25, P11, P12 | `wbsel = 00` selects the ALU result. P25 forwards 12 to the register file, which writes it into x7 because `regwrite = 1`. |
| Next PC | P03, P16, P15, P14 | P03 calculates PC + 4 = `0x244`. P16 selects the sequential next-PC path, and P15 supplies `0x244` to P14. |

**Control word:**

The control word for an OP instruction is `0x4000`.

Its important control signals are:

- `regwrite = 1`: write the result into the destination register.
- `wbsel = 00`: select the ALU result.
- `asel_pc = 0`: use the register operand instead of PC.
- `bsel_imm = 0`: use the second register operand instead of an immediate.
- `memread = 0`: no data-memory read.
- `memwrite = 0`: no data-memory write.

**Role of P25:**

P25 works during the write-back stage. For this ADD instruction, `wbsel = 00` selects the ALU result rather than memory data, PC+4 or the CSR value. P25 forwards the result 12 to the register file, where it is written into destination register x7.

The simulator trace confirms that x7 receives `0x0000000c`.

RC-V is a single-cycle processor, so fetch, decode, execute, memory and write-back are stages of the same instruction cycle, not separate clock cycles.

## E2 Neighbour review
**P24 — Control selector and checker**

Reviewed PR #131, which updates the P24 dossier.

I noticed that the E4 syllabus checklist used `[x]` for topics that were not covered. In Markdown, `[x]` represents a checked item, so these topics could appear selected as well. I submitted a review comment recommending `[x]` for completed topics and `[ ]` for topics not covered, using consistent Markdown checkbox syntax.

Review comment:
https://github.com/campus-sutra/rc-v/pull/131/changes#r4584855119

**P26 — ALU operand selector**

I searched the original RC-V repository for P26 pull requests, but no matching open or closed pull request was available when I attempted the review on 16 November 2026. Therefore, I could not submit a P26 review comment.

## E3 Where my block sits
P25 is part of the datapath, specifically the write-back stage of the RC-V processor. It receives the ALU result, the extended memory value from P28, PC+4 and the CSR read value, while P24 provides the `wbsel` control signal to select the required source. Its 32-bit output is sent to the register file (P11/P12), which writes the selected value into the destination register.

## E4 Syllabus map
The following syllabus topics were covered during my P25 project work (main focus: Unit 4).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [x] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA

The project mainly covered combinational logic, multiplexing, register write-back, instruction decoding, number representations and processor organisation. Some topics grouped in the checklist, such as K-maps, flip-flops, counters and DMA, were not implemented directly.