// P39 Trap controller
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p39_trap_ctrl (
    input  wire stall,
    input  wire irq,
    input  wire [4:0] irq_cause,
    input  wire mie,
    input  wire illegal,
    input  wire is_ecall,
    output wire trap,
    output wire [31:0] cause
);

    wire ei = ~stall & irq & mie;
wire il = ~stall & ~ei & illegal;
wire ec = ~stall & ~ei & ~il & is_ecall;

assign trap = ei | il | ec;
assign cause = ei ? (32'h80000010 + irq_cause) :
               il ? 32'd2 :
               ec ? 32'd11 : 32'd0;

endmodule
