`timescale 1ns / 1ps

// Uncomment this line only if extra-credit display messages are enabled (Must also toggle define USE_UI_COUNT_MESSAGES in top.v)
// `define USE_SEGMENT_MESSAGES

module seven_segment_inf (
    input clk,              // 100 MHz clock
    input rst,
    input [5:0] count,     // 0-59 seconds normally; 60-63 reserved for messages if enabled
    output [3:0] anode,
    output reg [6:0] segs
);

// 1. Generate Scan Clock (~1 kHz)
reg [15:0] scan_cnt = 0;
wire scan_clk;

always @(posedge clk) begin
    if (rst)
        scan_cnt <= 0;
    else
        scan_cnt <= scan_cnt + 1;
end

assign scan_clk = scan_cnt[15];  // ~1 kHz


// 2. Split into tens/ones
wire [3:0] tens;
wire [3:0] ones;

assign tens = count / 10;
assign ones = count % 10;


// 3. Scanner (digit select)
reg [1:0] an_cnt;

always @(posedge scan_clk) begin
    if (rst)
        an_cnt <= 0;
    else
        an_cnt <= an_cnt + 1;
end

assign anode = ~(1 << an_cnt);  // "active-low"
                                // Cycles through:
                                //      an_cnt = 0 → anode = 1110 --> AN0 active
                                //      an_cnt = 1 → anode = 1101 --> AN1 active
                                //      an_cnt = 2 → anode = 1011 --> AN2 active
                                //      an_cnt = 3 → anode = 0111 --> AN3 active
                                // case(anode) then lets us chooses what character appears on that active digit.
                                
`ifdef USE_SEGMENT_MESSAGES
/////////////////////////////// UI EXTRA /////////////////////////////////// v
//////////////////////////////////////////////////////////////////////////
// EXTRA-CREDIT MESSAGE DISPLAY MODE
//
// Normal numeric values:
//      count = 0-59  --> display decimal number
//
// Reserved message values:
//      count = 60    --> LOAD
//      count = 61    --> SEt
//      count = 62    --> UP
//      count = 63    --> dn
//
// NOTE: top.v accesses seven_segment_inf exactly the same way.
//////////////////////////////////////////////////////////////////////////

// Character tokens
localparam [4:0] CH_0     = 5'd0;
localparam [4:0] CH_1     = 5'd1;
localparam [4:0] CH_2     = 5'd2;
localparam [4:0] CH_3     = 5'd3;
localparam [4:0] CH_4     = 5'd4;
localparam [4:0] CH_5     = 5'd5;
localparam [4:0] CH_6     = 5'd6;
localparam [4:0] CH_7     = 5'd7;
localparam [4:0] CH_8     = 5'd8;
localparam [4:0] CH_9     = 5'd9;
localparam [4:0] CH_A     = 5'd10;  // A
localparam [4:0] CH_d     = 5'd11;  // d or "D"-like
localparam [4:0] CH_E     = 5'd12;  // E
localparam [4:0] CH_I     = 5'd13;  // same as "1"
localparam [4:0] CH_L     = 5'd14;  // L
localparam [4:0] CH_n     = 5'd15;  // roughly "n"
localparam [4:0] CH_O     = 5'd16;  // same as "0"
localparam [4:0] CH_P     = 5'd17;  // P
localparam [4:0] CH_S     = 5'd18;  // same as "5"
localparam [4:0] CH_t     = 5'd19;  // roughly "t"
localparam [4:0] CH_U     = 5'd20;  // U
localparam [4:0] CH_BLANK = 5'd31;  // space

// 4. Select digit to display
reg [4:0] selected;

always @(*) begin
    selected = CH_BLANK;

    case(anode)

        // Rightmost digit: AN0 active, anode = 1110
        4'b1110: begin
            if (count == 6'd60)
                selected = CH_d;          // LOAD
            else if (count == 6'd61)
                selected = CH_t;          //  SEt
            else if (count == 6'd62)
                selected = CH_P;          //   UP
            else if (count == 6'd63)
                selected = CH_n;          //   dn
            else
                selected = {1'b0, ones};  // normal numeric display
        end

        // Second from right: AN1 active, anode = 1101
        4'b1101: begin
            if (count == 6'd60)
                selected = CH_A;          // LOAD
            else if (count == 6'd61)
                selected = CH_E;          //  SEt
            else if (count == 6'd62)
                selected = CH_U;          //   UP
            else if (count == 6'd63)
                selected = CH_d;          //   dn
            else
                selected = {1'b0, tens};  // normal numeric display
        end

        // Second from left: AN2 active, anode = 1011
        4'b1011: begin
            if (count == 6'd60)
                selected = CH_O;          // LOAD
            else if (count == 6'd61)
                selected = CH_S;          //  SEt
            else
                selected = CH_BLANK;      // UP/dn are right-aligned
        end

        // Leftmost digit: AN3 active, anode = 0111
        4'b0111: begin
            if (count == 6'd60)
                selected = CH_L;          // LOAD
            else
                selected = CH_BLANK;      // SEt/UP/dn are right-aligned
        end

        default: begin
            selected = CH_BLANK;
        end
    endcase
end


// 5. 7-Segment Decoder
// GFEDCBA active-low
always @(*) begin
    case(selected)

        // Numbers
        CH_0: segs = 7'b1000000;
        CH_1: segs = 7'b1111001;
        CH_2: segs = 7'b0100100;
        CH_3: segs = 7'b0110000;
        CH_4: segs = 7'b0011001;
        CH_5: segs = 7'b0010010;
        CH_6: segs = 7'b0000010;
        CH_7: segs = 7'b1111000;
        CH_8: segs = 7'b0000000;
        CH_9: segs = 7'b0010000;

        // Letters / approximations
        CH_A: segs = 7'b0001000;      // A
        CH_d: segs = 7'b0100001;      // d
        CH_E: segs = 7'b0000110;      // E
        CH_L: segs = 7'b1000111;      // L
        CH_n: segs = 7'b0101011;      // n
        CH_O: segs = 7'b1000000;      // O, same as 0
        CH_P: segs = 7'b0001100;      // P
        CH_S: segs = 7'b0010010;      // S, same as 5
        CH_t: segs = 7'b0000111;      // t
        CH_U: segs = 7'b1000001;      // U

        default: segs = 7'b1111111;   // blank
    endcase
end


`else
/////////////////////////////// END UI EXTRA /////////////////////////////// ^


//////////////////////////////////////////////////////////////////////////
// DEFAULT ORIGINAL NUMERIC DISPLAY MODE
//      - Keeping this branch as close as possible to original
//////////////////////////////////////////////////////////////////////////
// 4. Select digit to display
reg [3:0] selected;

always @(*) begin
    case(anode)
        4'b1110: selected = ones;   // rightmost
        4'b1101: selected = tens;
        4'b1011: selected = 4'd15;  // blank
        4'b0111: selected = 4'd15;  // blank
        default: selected = 4'd15;
    endcase
end


// 5. 7-Segment Decoder
// GFEDCBA active-low
always @(*) begin
    case(selected)
        0: segs = 7'b1000000;
        1: segs = 7'b1111001;
        2: segs = 7'b0100100;
        3: segs = 7'b0110000;
        4: segs = 7'b0011001;
        5: segs = 7'b0010010;
        6: segs = 7'b0000010;
        7: segs = 7'b1111000;
        8: segs = 7'b0000000;
        9: segs = 7'b0010000;
        default: segs = 7'b1111111; // blank
    endcase
end

`endif

endmodule