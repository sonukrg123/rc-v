# P58 Branch predictor (2-bit counters) - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
My circuit uses a 2-bit saturating counter to predict whether a branch will be taken.

| Current state | Taken (1) | Not taken (0) |
|---|---|---|
| 00 | 01 | 00 |
| 01 | 10 | 00 |
| 10 | 11 | 01 |
| 11 | 11 | 10 |

The most significant bit gives the prediction. A 0 means not taken, and a 1 means taken.

The circuit uses AND, OR and NOT gates, multiplexers and flip-flops to calculate and store the counter state.

## U2 Digital components
The P58 branch predictor uses digital components to store and update branch predictions.

- **Registers:** Store the branch predictor's counters and statistics.
- **Multiplexers:** Select the required data and control signals.
- **Decoders:** Help select the required register or counter.
- **Flip-flops:** Store the 2-bit counter states.
- **Memory:** Stores the predictor information so it can be read and updated.
- **Connections:** Control signals determine when the predictor reads, writes or updates its data.

These components work together to predict branch outcomes and maintain prediction statistics.

## U3 Data representation
The branch predictor uses binary values to represent its 2-bit counter states.

| Binary | Hexadecimal | Decimal |
|---|---|---|
| 00 | 0x0 | 0 |
| 01 | 0x1 | 1 |
| 10 | 0x2 | 2 |

The counter has a range of 0 to 3. If it receives another increment while at 3, it stays at 3. If it receives another decrement while at 0, it stays at 0. This is called saturation and prevents overflow or underflow.

The counter uses unsigned binary representation, so sign extension is not required.

## U4 Computer organisation
The P58 branch predictor is part of the processor's control-flow system.

1. **Fetch:** The processor uses branch prediction information to estimate the next instruction address.
2. **Decode:** The instruction is decoded to identify whether it is a branch.
3. **Execute:** The branch condition is evaluated and the actual outcome is determined.
4. **Update:** The predictor's counter is updated using the actual branch outcome.
5. **Next instruction:** The processor continues using the correct instruction flow.

Branch prediction helps reduce delays caused by branches in a program.
## U5 Processors
Processors can use different architectures:

- **CISC:** Uses complex instructions that can perform multiple operations.
- **Stack-based processor:** Uses a stack to store operands and perform operations.
- **GPU:** Contains many processing units designed to perform parallel operations.

The RC-V processor uses its own instruction set and datapath. P58 supports its control flow by predicting branch outcomes. It helps the processor reduce delays when executing branch instructions.

For more details about the RC-V architecture, refer to `docs/ARCHITECTURE.md`.

## U6 Memory and I/O
The P58 branch predictor stores information about branch behaviour so that the processor can make future predictions.

It uses registers and counters to store prediction states and statistics. The processor can read prediction information and update it when a branch instruction is completed.

Memory allows the predictor to retain this information, while input/output control signals allow the processor to communicate with the predictor.

This improves processor performance by reducing delays caused by incorrect branch predictions.

## E1 Instruction trace: SLTI
The SLTI (Set Less Than Immediate) instruction compares a signed register value with a sign-extended immediate value. It writes 1 to the destination register if the register value is smaller; otherwise, it writes 0.

The instruction passes through these blocks:

1. **Fetch:** P14 (PC) provides the address and P30 (ROM) fetches the instruction.
2. **Decode:** P17 extracts instruction fields. P21, P22/P23 and P24 decode the instruction. P18 and P19 generate the immediate, and P20 selects it.
3. **Register read:** P13 reads the source register through P11 and P12.
4. **Execute:** P26 selects the operands, P10 controls the ALU, and P01–P08 perform the signed comparison.
5. **Memory:** No data-memory access is needed for SLTI.
6. **Write-back:** P25 selects the ALU result, and P11/P12 write it into the destination register.
7. **Next PC:** P03, P16 and P15 select the next sequential instruction address.

The important signals are the source register value, sign-extended immediate, ALU result (0 or 1), register write enable and destination register address.
## E2 Neighbour review
The implementation is well organised and the changes are clearly explained. The testing details are helpful. It would be even better to include a simple example showing how the branch predictor updates its 2-bit counter after a branch is taken and after a branch is not taken. This would make the behaviour easier to understand and verify.
## E3 Where my block sits
P58 belongs to the hardware and digital logic layer of the RC-V processor system. It is a memory-mapped I/O device connected to the processor through the system bus. The CPU communicates with it using its registers to read branch prediction information, update branch counters and clear statistics. It helps the processor make better branch predictions and reduce control-flow delays.
## E4 Syllabus map
## E4 Syllabus map

- [x] Logic gates, Boolean algebra, K-maps (logic gates and Boolean expressions; no K-maps used)
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA (memory-mapped I/O interface)
