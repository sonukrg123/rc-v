// P19 Immediate generator B/J/U
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
module p19_imm_bju (
    input  wire [31:0] instr,
    output wire [31:0] imm_b,
    output wire [31:0] imm_j,
    output wire [31:0] imm_u
);

    // B-type: 13-bit, bit 0 is always 0, sign-extended from instr[31]
    //   imm[12]=i[31]  imm[11]=i[7]  imm[10:5]=i[30:25]  imm[4:1]=i[11:8]  imm[0]=0
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    // J-type: 21-bit, bit 0 is always 0, sign-extended from instr[31]
    //   imm[20]=i[31]  imm[19:12]=i[19:12]  imm[11]=i[20]  imm[10:1]=i[30:21]  imm[0]=0
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    // U-type: upper 20 bits, low 12 bits zero
    assign imm_u = {instr[31:12], 12'b0};

endmodule