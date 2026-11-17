// P61 Text screen: 4 rows x 16 columns, I/O device slot 19
// Registers (ridx): 0 CHAR (write), 1 CURSOR (read/write), 2 CLEAR (write),
//                   3 READ (read: character under the cursor), 15 ID (reads 61)
module p61_text_screen (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire [5:0] dbg_addr,
    output wire [7:0] dbg_char
);

    reg [7:0] screen [0:63];   // 64 characters, index = row*16 + column
    reg [5:0] cursor;          // same cursor logic as P61.dig
    integer i;

    wire wr      = sel & we;
    wire is_nl   = (wdata[7:0] == 8'h0A);
    wire [1:0] next_row = cursor[5:4] + 2'd1;   // wraps 3 -> 0
    wire [7:0] cur_char = screen[cursor];

    // reads do not wait for the clock and do not depend on sel/re
    assign rdata = (ridx == 4'd1)  ? {26'd0, cursor}  :
                   (ridx == 4'd3)  ? {24'd0, cur_char} :
                   (ridx == 4'd15) ? 32'd61            :
                                     32'd0;

    assign dbg_char = screen[dbg_addr];

    always @(posedge clk) begin
        if (rst) begin
            cursor <= 6'd0;
            for (i = 0; i < 64; i = i + 1)
                screen[i] <= 8'h20;
        end else if (wr) begin
            case (ridx)
                4'd0: begin                              // CHAR
                    if (is_nl) begin
                        cursor <= {next_row, 4'd0};
                    end else begin
                        screen[cursor] <= wdata[7:0];
                        cursor <= cursor + 6'd1;         // wraps 63 -> 0
                    end
                end
                4'd1: cursor <= wdata[5:0];              // CURSOR
                4'd2: begin                              // CLEAR
                    cursor <= 6'd0;
                    for (i = 0; i < 64; i = i + 1)
                        screen[i] <= 8'h20;
                end
                default: ;
            endcase
        end
    end

endmodule
