// P01 ALU adder/subtractor
// y = a + b when sub = 0, y = a - b when sub = 1 (computed as a + ~b + 1)
// c = carry out of the 32-bit addition
// v = signed overflow = carry into bit 31 XOR carry out of bit 31
module p01_alu_addsub (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire sub,
    output wire [31:0] y,
    output wire c,
    output wire v
);

    // XOR gates on b: b when sub = 0, ~b when sub = 1
    wire [31:0] bx = b ^ {32{sub}};

    // full 32-bit sum with carry out (33 bits); sub is the carry-in (the "+1")
    wire [32:0] sum = {1'b0, a} + {1'b0, bx} + {32'b0, sub};

    // carry into bit 31 = carry out of the lower 31 bits
    wire [31:0] low = {1'b0, a[30:0]} + {1'b0, bx[30:0]} + {31'b0, sub};
    wire c31 = low[31];

    assign y = sum[31:0];
    assign c = sum[32];
    assign v = c31 ^ sum[32];

endmodule