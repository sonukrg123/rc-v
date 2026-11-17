// P22 hardwired control unit: one OR-of-classes equation per output bit.
module p22_ctrl_hw (
    input wire is_lui,
    input wire is_auipc,
    input wire is_jal,
    input wire is_jalr,
    input wire is_branch,
    input wire is_load,
    input wire is_store,
    input wire is_opimm,
    input wire is_op,
    input wire is_system,
    output wire [15:0] ctrl
);
    assign ctrl[0] = is_system;
    assign ctrl[1] = is_jalr;
    assign ctrl[2] = is_jal;
    assign ctrl[3] = is_branch;
    assign ctrl[4] = is_lui | is_auipc | is_store;
    assign ctrl[5] = is_lui | is_auipc | is_branch;
    assign ctrl[6] = is_jal;
    assign ctrl[7] = is_load | is_system;
    assign ctrl[8] = is_jal | is_jalr | is_system;
    assign ctrl[9] = is_store;
    assign ctrl[10] = is_load;
    assign ctrl[11] = is_lui;
    assign ctrl[12] = is_lui | is_auipc | is_jalr | is_load | is_store | is_opimm;
    assign ctrl[13] = is_auipc;
    assign ctrl[14] = is_lui | is_auipc | is_jal | is_jalr | is_load | is_opimm | is_op | is_system;
    assign ctrl[15] = 1'b0;
endmodule
