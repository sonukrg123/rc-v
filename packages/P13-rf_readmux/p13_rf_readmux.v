// P13 Register-file read port
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p13_rf_readmux (
    input  wire [1023:0] q_flat,
    input  wire [4:0] ra,
    output wire [31:0] rd
);

    assign rd = q_flat[ra*32 +: 32];

endmodule
