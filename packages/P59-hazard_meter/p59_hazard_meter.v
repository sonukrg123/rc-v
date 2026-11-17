// P59 Pipeline hazard meter
// Keep the module name and the port list exactly as they are.
module p59_hazard_meter (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire commit,
    input  wire [31:0] instr,
    input  wire rf_we,
    input  wire [4:0] rd,
    input  wire is_load
);

    // ---- decode the source registers of the committed instruction ----
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];

    wire uses_rs1 = (opcode == 7'b1100111) |  // JALR
                    (opcode == 7'b1100011) |  // BRANCH
                    (opcode == 7'b0000011) |  // LOAD
                    (opcode == 7'b0100011) |  // STORE
                    (opcode == 7'b0010011) |  // OP-IMM
                    (opcode == 7'b0110011);   // OP
    wire uses_rs2 = (opcode == 7'b1100011) |  // BRANCH
                    (opcode == 7'b0100011) |  // STORE
                    (opcode == 7'b0110011);   // OP

    // ---- remember the previous committed instruction ----
    reg [4:0] prev_rd;
    reg       prev_we;
    reg       prev_load;
    reg       prev_valid;

    wire prev_writes = prev_valid & prev_we & (prev_rd != 5'd0);
    wire match = prev_writes &
                 ((uses_rs1 & (rs1 == prev_rd)) |
                  (uses_rs2 & (rs2 == prev_rd)));

    reg [31:0] raw_cnt;
    reg [31:0] lu_cnt;

    wire do_clear = sel & we & (ridx == 4'd2);

    always @(posedge clk) begin
        if (rst) begin
            prev_rd    <= 5'd0;
            prev_we    <= 1'b0;
            prev_load  <= 1'b0;
            prev_valid <= 1'b0;
            raw_cnt    <= 32'd0;
            lu_cnt     <= 32'd0;
        end else begin
            if (commit) begin
                prev_rd    <= rd;
                prev_we    <= rf_we;
                prev_load  <= is_load;
                prev_valid <= 1'b1;
            end
            if (do_clear) begin
                raw_cnt <= 32'd0;
                lu_cnt  <= 32'd0;
            end else if (commit & match) begin
                raw_cnt <= raw_cnt + 32'd1;
                if (prev_load)
                    lu_cnt <= lu_cnt + 32'd1;
            end
        end
    end

    // ---- register read: 0 = LOADUSE, 1 = RAW1, 15 = package number ----
    assign rdata = (ridx == 4'd0)  ? lu_cnt :
                   (ridx == 4'd1)  ? raw_cnt :
                   (ridx == 4'd15) ? 32'd59 : 32'd0;

endmodule
