// P24 Control selector and checker
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p24_ctrl_check (
    input  wire [15:0] ctrl_hw,
    input  wire [15:0] ctrl_rom,
    input  wire use_rom,
    output wire [15:0] ctrl,
    output wire mismatch
);

    assign ctrl = use_rom ? ctrl_rom : ctrl_hw;   
     assign mismatch = (ctrl_hw != ctrl_rom);   

endmodule
