// P50 Multiplier (shift and add)
// I/O device slot 8. Register map (ridx):
//   0 = A       (read/write)
//   1 = B       (read/write)
//   2 = CTRL    (write bit0 = start, reads 0)
//   3 = STATUS  (bit0 = busy, read only)
//   4 = RESULT  (low 32 bits of A*B, read only)
//   15 = ID     (always reads 50, the package number)
// Everything else reads 0. Multiplication takes 32 clock cycles,
// one bit of B per cycle. A start while busy is ignored.
module p50_mul_unit (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] reg_a;     // operand A as written by the CPU
    reg [31:0] reg_b;     // operand B as written by the CPU
    reg [31:0] mcand;     // working copy of A, shifts left each cycle
    reg [31:0] mplier;    // working copy of B, shifts right each cycle
    reg [31:0] acc;       // accumulator = RESULT
    reg [4:0]  cnt;       // counts the 32 cycles
    reg        busy;

    wire wr_a    = sel & we & (ridx == 4'd0);
    wire wr_b    = sel & we & (ridx == 4'd1);
    wire wr_ctrl = sel & we & (ridx == 4'd2);
    wire start   = wr_ctrl & wdata[0] & ~busy;

    always @(posedge clk) begin
        if (rst) begin
            reg_a  <= 32'd0;
            reg_b  <= 32'd0;
            mcand  <= 32'd0;
            mplier <= 32'd0;
            acc    <= 32'd0;
            cnt    <= 5'd0;
            busy   <= 1'b0;
        end else begin
            if (wr_a) reg_a <= wdata;
            if (wr_b) reg_b <= wdata;

            if (start) begin
                // latch operands so writes during the run do not disturb it
                mcand  <= reg_a;
                mplier <= reg_b;
                acc    <= 32'd0;
                cnt    <= 5'd0;
                busy   <= 1'b1;
            end else if (busy) begin
                if (mplier[0]) acc <= acc + mcand;   // add if current bit of B is 1
                mcand  <= mcand << 1;
                mplier <= mplier >> 1;
                cnt    <= cnt + 5'd1;
                if (cnt == 5'd31) busy <= 1'b0;      // 32nd cycle done
            end
        end
    end

    // read side: simple multiplexer on ridx
    reg [31:0] rd;
    always @(*) begin
        case (ridx)
            4'd0:    rd = reg_a;
            4'd1:    rd = reg_b;
            4'd3:    rd = {31'd0, busy};
            4'd4:    rd = acc;
            4'd15:   rd = 32'd50;
            default: rd = 32'd0;
        endcase
    end
    assign rdata = rd;

endmodule
