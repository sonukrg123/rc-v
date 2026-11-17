// P04 ALU logic unit
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p04_alu_logic (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [1:0] op,
    output wire [31:0] y
);

    assign y = (op==2'd0)?(a&b):
        (op==2'd1)?(a|b):
        (op==2'd2)?(a^b):
              32'd0;// placeholder

endmodule
