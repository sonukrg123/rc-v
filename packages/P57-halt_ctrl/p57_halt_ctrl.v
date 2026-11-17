// P57 Halt controller
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p57_halt_ctrl (
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
    output wire halted
);

    // assign rdata = 32'd0;   // placeholder
    // assign halted = 1'd0;   // placeholder

        reg [31:0] code_reg;
    reg halt_reg;

    always @(posedge clk) begin
        if (rst) begin
            code_reg <= 32'd0;
            halt_reg <= 1'b0;
        end else begin
            if (sel && we && ridx == 4'h1)
                code_reg <= wdata;

            if (sel && we && ridx == 4'h0 && wdata[0])
                halt_reg <= 1'b1;

            if (commit && instr == 32'h0000006F)
                halt_reg <= 1'b1;
        end
    end

    assign rdata = (ridx == 4'h0) ? {31'd0, halt_reg} :
                   (ridx == 4'h1) ? code_reg :
                   (ridx == 4'hf) ? 32'h00000039 :
                   32'd0;

    assign halted = halt_reg;

endmodule
