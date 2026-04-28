`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2026 08:57:46 PM
// Design Name: 
// Module Name: seven_segment_inf_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module seven_segment_inf_test;

    // Testbench bookkeeping
    integer test = 0;
    integer fail = 0;

    // DUT inputs
    reg clk = 0;
    reg rst = 0;
    reg [5:0] count = 0;

    // DUT outputs
    wire [3:0] anode;
    wire [6:0] segs;

    // DUT
    seven_segment_inf dut(
        .clk(clk),
        .rst(rst),
        .count(count),
        .anode(anode),
        .segs(segs)
    );

    // 100 MHz equivalent clock: 10 ns period
    always #5 clk = ~clk;


    ////////////////////////////////////////////////////////////////
    // Segment constants
    // These must match seven_segment_inf.v
    // GFEDCBA active-low
    ////////////////////////////////////////////////////////////////

    localparam [6:0] SEG_0     = 7'b1000000;
    localparam [6:0] SEG_1     = 7'b1111001;
    localparam [6:0] SEG_2     = 7'b0100100;
    localparam [6:0] SEG_3     = 7'b0110000;
    localparam [6:0] SEG_4     = 7'b0011001;
    localparam [6:0] SEG_5     = 7'b0010010;
    localparam [6:0] SEG_6     = 7'b0000010;
    localparam [6:0] SEG_7     = 7'b1111000;
    localparam [6:0] SEG_8     = 7'b0000000;
    localparam [6:0] SEG_9     = 7'b0010000;

    localparam [6:0] SEG_A     = 7'b0001000;
    localparam [6:0] SEG_d     = 7'b0100001;
    localparam [6:0] SEG_E     = 7'b0000110;
    localparam [6:0] SEG_L     = 7'b1000111;
    localparam [6:0] SEG_n     = 7'b0101011;
    localparam [6:0] SEG_O     = 7'b1000000;
    localparam [6:0] SEG_P     = 7'b0001100;
    localparam [6:0] SEG_S     = 7'b0010010;
    localparam [6:0] SEG_t     = 7'b0000111;
    localparam [6:0] SEG_U     = 7'b1000001;

    localparam [6:0] SEG_BLANK = 7'b1111111;


    ////////////////////////////////////////////////////////////////
    // Wait until a specific anode is active, then check segs.
    ////////////////////////////////////////////////////////////////

    task automatic check_digit;
        input [3:0] expected_anode;
        input [6:0] expected_segs;
        input [255:0] label;

        integer timeout;
    begin
        timeout = 0;

        // Wait for the display scanner to reach the requested digit.
        while ((anode !== expected_anode) && (timeout < 1000000)) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        // Give combinational segs logic one tiny delay to settle.
        #1;

        if (timeout >= 1000000) begin
            fail = fail + 1;
            $display("FAILED: %0s | Timed out waiting for anode=%b. Current anode=%b segs=%b",
                     label, expected_anode, anode, segs);
        end
        else if (segs !== expected_segs) begin
            fail = fail + 1;
            $display("FAILED: %0s | anode=%b expected segs=%b observed segs=%b",
                     label, expected_anode, expected_segs, segs);
        end
        else begin
            $display("Passed: %0s | anode=%b segs=%b",
                     label, anode, segs);
        end
    end
    endtask


    ////////////////////////////////////////////////////////////////
    // Check a full 4-character display word/message.
    //
    // Character order:
    //      leftmost       anode = 0111
    //      second-left    anode = 1011
    //      second-right   anode = 1101
    //      rightmost      anode = 1110
    ////////////////////////////////////////////////////////////////

    task automatic check_four_digits;
        input [5:0] test_count;
        input [6:0] leftmost;
        input [6:0] second_left;
        input [6:0] second_right;
        input [6:0] rightmost;
        input [255:0] message_name;
    begin
        test = test + 1;
        count = test_count;

        $display("");
        $display("Test %0d: Display %0s using count=%0d", test, message_name, test_count);

        // Wait a little after changing count.
        repeat (10) @(posedge clk);

        check_digit(4'b0111, leftmost,     {message_name, " leftmost"});
        check_digit(4'b1011, second_left,  {message_name, " second_left"});
        check_digit(4'b1101, second_right, {message_name, " second_right"});
        check_digit(4'b1110, rightmost,    {message_name, " rightmost"});

        $display("Test %0d complete: %0s", test, message_name);
    end
    endtask


    ////////////////////////////////////////////////////////////////
    // Test sequence
    ////////////////////////////////////////////////////////////////

    initial begin
        $timeformat(-9, 0, " ns", 6);

        $display("Seven-segment display test starting...");
        $display("NOTE: For LOAD/SEt/UP/dn tests, USE_SEGMENT_MESSAGES must be enabled in seven_segment_inf.v.");

        // Reset
        rst = 1;
        count = 6'd0;
        #100;
        rst = 0;
        
        // The original seven_segment_inf.v scanner uses an internal an_cnt
        // clocked by scan_clk. In simulation, an_cnt can remain X because
        // it is not initialized before scan_clk begins toggling.
        // Force it once here so this display-only testbench can observe
        // the provided scanner behavior without modifying the design file.
        force dut.an_cnt = 2'd0;
        #1;
        release dut.an_cnt;
        
        // Let scanner start running.
        #1000;

        // Test special message codes.
        check_four_digits(
            6'd60,
            SEG_L, SEG_O, SEG_A, SEG_d,
            "LOAD"
        );

        check_four_digits(
            6'd61,
            SEG_BLANK, SEG_S, SEG_E, SEG_t,
            "SEt"
        );

        check_four_digits(
            6'd62,
            SEG_BLANK, SEG_BLANK, SEG_U, SEG_P,
            "UP"
        );

        check_four_digits(
            6'd63,
            SEG_BLANK, SEG_BLANK, SEG_d, SEG_n,
            "dn"
        );

        // Test normal numeric value 42.
        // Original display is right-aligned over two digits:
        // left two blank, tens=4, ones=2.
        check_four_digits(
            6'd42,
            SEG_BLANK, SEG_BLANK, SEG_4, SEG_2,
            "42"
        );

        $display("");

        if (fail > 0) begin
            $error("Seven-segment display tests FAILED. Tests Passed = %0d/%0d", test - fail, test);
        end
        else begin
            $display("All Seven-Segment Display Tests Passed! Testcases Passed = %0d/%0d", test, test);
        end

        $finish;
    end
    
    ////////////////////////////////////////////////////////////////
    // Simulation watchdog
    // If the testbench hangs or Vivado is run for long enough,
    // this forces the simulation to end with a useful message.
    ////////////////////////////////////////////////////////////////
    initial begin
        #50_000_000; // 50 ms with `timescale 1ns / 1ps
        $error("Seven-segment display test timed out before completing.");
        $finish;
    end

endmodule
