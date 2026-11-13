// P40 Illegal-instruction detector
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Design: illegal = 1 when instr is not one of the RC-V instructions (combinational).
module p40_illegal_detect (
    input  wire [31:0] instr,
    output wire illegal
);

    wire [6:0] op = instr[6:0];     // opcode
    wire [2:0] f3 = instr[14:12];   // funct3
    wire [6:0] f7 = instr[31:25];   // funct7

    wire f7_zero = (f7 == 7'h00);
    wire f7_sub  = (f7 == 7'h20);

    // opcodes
    wire is_lui    = (op == 7'h37);
    wire is_auipc  = (op == 7'h17);
    wire is_jal    = (op == 7'h6F);
    wire is_jalr   = (op == 7'h67);
    wire is_branch = (op == 7'h63);
    wire is_load   = (op == 7'h03);
    wire is_store  = (op == 7'h23);
    wire is_opimm  = (op == 7'h13);
    wire is_op     = (op == 7'h33);
    wire is_system = (op == 7'h73);

    // legal combinations
    wire legal_jalr   = is_jalr   & (f3 == 3'd0);
    wire legal_branch = is_branch & (f3 != 3'd2) & (f3 != 3'd3);
    wire legal_load   = is_load   & ((f3 == 3'd0) | (f3 == 3'd2) | (f3 == 3'd4));
    wire legal_store  = is_store  & ((f3 == 3'd0) | (f3 == 3'd2));
    wire legal_opimm  = is_opimm  & ( (f3 == 3'd1) ? f7_zero :
                                      (f3 == 3'd5) ? (f7_zero | f7_sub) : 1'b1 );
    wire legal_op     = is_op     & ( f7_zero | (f7_sub & ((f3 == 3'd0) | (f3 == 3'd5))) );
    wire legal_system = is_system & ( (instr == 32'h00000073) |      // ecall
                                      (instr == 32'h30200073) |      // mret
                                      (f3 == 3'd1) | (f3 == 3'd2) | (f3 == 3'd3) ); // csrrw/s/c

    wire legal = is_lui | is_auipc | is_jal | legal_jalr | legal_branch |
                 legal_load | legal_store | legal_opimm | legal_op | legal_system;

    assign illegal = ~legal;

endmodule