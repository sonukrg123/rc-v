// P06 Right barrel shifter
module p06_shift_right (
    input  wire [31:0] a,
    input  wire [4:0]  sh,
    input  wire        arith,
    output wire [31:0] y
);

    // Compute sign extension bit: sin = a[31] AND arith
    wire sin = a[31] & arith;

    // 5-stage barrel shifter (shifts by 1, 2, 4, 8, 16)
    wire [31:0] s0 = sh[0] ? {sin, a[31:1]}        : a;
    wire [31:0] s1 = sh[1] ? {{2{sin}}, s0[31:2]}  : s0;
    wire [31:0] s2 = sh[2] ? {{4{sin}}, s1[31:4]}  : s1;
    wire [31:0] s3 = sh[3] ? {{8{sin}}, s2[31:8]}  : s2;
    wire [31:0] s4 = sh[4] ? {{16{sin}}, s3[31:16]} : s3;

    assign y = s4;

endmodule
