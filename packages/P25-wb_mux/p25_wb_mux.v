
// P25 Write-back selector

module p25_wb_mux (
    input  wire [1:0]  wbsel,
    input  wire [31:0] alu_y,
    input  wire [31:0] mem_val,
    input  wire [31:0] pc4,
    input  wire [31:0] csr_rd,
    output reg  [31:0] wd
);

    always @(*) begin
        case (wbsel)
            2'b00: wd = alu_y;
            2'b01: wd = mem_val;
            2'b10: wd = pc4;
            2'b11: wd = csr_rd;

            default: wd = 32'd0;
        endcase
    end

endmodule
