// P47 Interrupt controller (I/O slot 4)
// Registers: 0 PENDING, 1 MASK, 2 CAUSE, 3 SWI, 15 = package number (47)
// Sources: 0 timer, 1 keyboard, 2 DMA done, 3 stack guard (from 'lines'), 4 software (SWI)
module p47_irq_ctrl (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire [3:0] lines,
    output wire irq,
    output wire [4:0] cause
);

    reg [4:0] mask;   // MASK register: 1 = source enabled
    reg       swi;    // software interrupt flag (source 4)

    // PENDING follows the device lines (level) plus the software flag
    wire [4:0] pending = {swi, lines};
    wire [4:0] m       = pending & mask;      // masking AND gates

    assign irq = |m;

    // priority encoder: lowest-numbered active source wins, 31 if none
    assign cause = m[0] ? 5'd0 :
                   m[1] ? 5'd1 :
                   m[2] ? 5'd2 :
                   m[3] ? 5'd3 :
                   m[4] ? 5'd4 : 5'd31;

    // writes at the rising edge
    always @(posedge clk) begin
        if (rst) begin
            mask <= 5'd0;
            swi  <= 1'b0;
        end else if (sel && we) begin
            case (ridx)
                4'd1: mask <= wdata[4:0];
                4'd3: swi  <= wdata[0];      // write 1 = raise, write 0 = clear
                default: ;
            endcase
        end
    end

    // rdata always shows register ridx
    always @(*) begin
        case (ridx)
            4'd0:    rdata = {27'd0, pending};
            4'd1:    rdata = {27'd0, mask};
            4'd2:    rdata = {27'd0, cause};
            4'd3:    rdata = {31'd0, swi};
            4'd15:   rdata = 32'd47;
            default: rdata = 32'd0;
        endcase
    end

endmodule
