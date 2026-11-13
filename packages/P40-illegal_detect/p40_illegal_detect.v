// P40 Illegal-instruction detector
// RC-V implements the RV32I subset documented in docs/ISA.md.
module p40_illegal_detect (
    input  wire [31:0] instr,
    output wire illegal
);
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    wire is_rtype = (opcode == 7'h33);
    wire is_itype = (opcode == 7'h13);
    wire is_load  = (opcode == 7'h03);
    wire is_store = (opcode == 7'h23);
    wire is_branch= (opcode == 7'h63);
    wire is_jal   = (opcode == 7'h6f);
    wire is_jalr  = (opcode == 7'h67);
    wire is_lui   = (opcode == 7'h37);
    wire is_auipc = (opcode == 7'h17);
    wire is_system= (opcode == 7'h73);

    // R-type: ADD/SUB and SRL/SRA have two legal funct7 values;
    // all other supported operations require funct7 == 0.
    wire r_f3_ok = (funct3 == 3'd0) || (funct3 == 3'd1) ||
                   (funct3 == 3'd2) || (funct3 == 3'd3) ||
                   (funct3 == 3'd4) || (funct3 == 3'd5) ||
                   (funct3 == 3'd6) || (funct3 == 3'd7);
    wire r_f7_ok = ((funct3 == 3'd0) || (funct3 == 3'd5))
                       ? ((funct7 == 7'h00) || (funct7 == 7'h20))
                       : (funct7 == 7'h00);
    wire r_valid = is_rtype && r_f3_ok && r_f7_ok;

    // Immediate ALU operations. Non-shift instructions use the remaining
    // bits as an immediate; shifts have restricted upper immediate bits.
    wire i_f3_ok = (funct3 == 3'd0) || (funct3 == 3'd2) ||
                   (funct3 == 3'd3) || (funct3 == 3'd4) ||
                   (funct3 == 3'd6) || (funct3 == 3'd7) ||
                   (funct3 == 3'd1) || (funct3 == 3'd5);
    wire i_shift_ok = (funct3 == 3'd1)
                       ? (funct7 == 7'h00)
                       : ((funct7 == 7'h00) || (funct7 == 7'h20));
    wire i_valid = is_itype && i_f3_ok &&
                   (((funct3 == 3'd1) || (funct3 == 3'd5))
                       ? i_shift_ok : 1'b1);

    wire load_valid = is_load &&
                      ((funct3 == 3'd0) || (funct3 == 3'd2) ||
                       (funct3 == 3'd4));
    wire store_valid = is_store &&
                       ((funct3 == 3'd0) || (funct3 == 3'd2));
    wire branch_valid = is_branch &&
                        ((funct3 == 3'd0) || (funct3 == 3'd1) ||
                         (funct3 == 3'd4) || (funct3 == 3'd5) ||
                         (funct3 == 3'd6) || (funct3 == 3'd7));
    wire jal_valid   = is_jal;
    wire jalr_valid  = is_jalr && (funct3 == 3'd0);
    wire upper_valid = is_lui || is_auipc;

    // SYSTEM supports ECALL, MRET, and register-form CSR operations.
    wire ecall_valid = (instr == 32'h00000073);
    wire mret_valid  = (instr == 32'h30200073);
    wire csr_valid   = is_system &&
                       ((funct3 == 3'd1) || (funct3 == 3'd2) ||
                        (funct3 == 3'd3));
    wire system_valid = ecall_valid || mret_valid || csr_valid;

    wire valid_instr = r_valid || i_valid || load_valid || store_valid ||
                       branch_valid || jal_valid || jalr_valid ||
                       upper_valid || system_valid;

    assign illegal = ~valid_instr;
endmodule
