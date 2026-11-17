// P27 Store aligner
module p27_store_align (
    input  wire [2:0]  funct3,
    input  wire [1:0]  addr_lo,
    input  wire [31:0] rs2,
    output reg  [31:0] wdata,
    output reg  [3:0]  be
);

    always @* begin
        case (funct3)
            3'b000: begin                  // SB
                wdata = {4{rs2[7:0]}};
                be    = 4'b0001 << addr_lo;
            end
            3'b001: begin                  // SH
                wdata = {2{rs2[15:0]}};
                be    = addr_lo[1] ? 4'b1100 : 4'b0011;
            end
            3'b010: begin                  // SW
                wdata = rs2;
                be    = 4'b1111;
            end
            default: begin
                wdata = rs2;
                be    = 4'b0000;
            end
        endcase
    end

endmodule
