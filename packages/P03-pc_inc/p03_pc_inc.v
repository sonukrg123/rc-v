// P03 PC incrementer
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p03_pc_inc (
    input  wire [31:0] pc,
    output wire [31:0] pc4
);

    assign pc4 = pc + 32'd4;   // placeholder

endmodule
