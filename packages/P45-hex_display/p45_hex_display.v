// P45 Hex display scanner
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Scan from the least-significant nibble to the most-significant nibble.
module p45_hex_display (
    input  wire clk,
    input  wire rst,
    input  wire [31:0] value,
    output wire [3:0] digit,
    output wire [7:0] anode
);

    reg [2:0] position;

    // Reset is synchronous and active high. Three bits wrap 7 back to 0.
    always @(posedge clk) begin
        if (rst)
            position <= 3'd0;
        else
            position <= position + 3'd1;
    end

    // The mux and decoder use the same position, keeping the outputs aligned.
    // value is live: a change to it is visible without waiting for another scan.
    assign digit = value[{position, 2'b00} +: 4];
    assign anode = 8'b00000001 << position;

endmodule
