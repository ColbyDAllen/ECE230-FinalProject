`timescale 1ns / 1ps

// Uncomment this line only if extra-credit UI display messages are enabled (Must also toggle define USE_SEGMENT_MESSAGES in seven_segment_inf.v)
// `define USE_UI_COUNT_MESSAGES

module top 
(
    input clk,              // 100 MHz
    input btnC,             // reset
    input [15:0] sw,        // switches
    output [15:0] led,      // LEDs
    output [3:0] an,        // Outputs for 7-segment display
    output [6:0] seg        // Outputs for 7-segment display
);


/******** DO NOT MODIFY ********/
wire clk_1Hz;           // Generate Internal 1Hz Clock
wire btnC_1Hz;          // Stretch load signal

// If running simulation, output clock frequency is 100MHz, else 1Hz
`ifndef SYNTHESIS
    assign clk_1Hz = clk;
`else
    clk_div #(.INPUT_FREQ(100_000_000), .OUTPUT_FREQ(1)) clk_div_1Hz 
    (.iclk(clk) , .rst(btnC) , .oclk(clk_1Hz));
`endif

// Check stopwatch/timer frequency
initial begin
`ifndef SYNTHESIS
    $display("Stopwatch/Timer Frequency set to 100MHz");
`else
    $display("Stopwatch/Timer Frequency set to 1Hz");
`endif
end

// Seven Segment Display Interface
seven_segment_inf seven_segment_inf_inst (.clk(clk), .rst(btnC), .count(count) , .anode(an), .segs(seg));
/****** END DO NOT MODIFY ******/


/******** UNCOMMENT & UPDATE THIS SECTION ********/
// wire "count" feeds in count value to seven segment display. This should be a 6-bit value

// This will decide if seven segment display shows stopwatch count or timer count

// wire [5:0] count = ;
wire [5:0] count;

// Internal stopwatch counts / toggles
wire [5:0] stopwatch_count;
wire stopwatch_en;              // On pausing, that is, en = 0, stopwatch should hold its state

// Internal timer counts / toggles
wire [5:0] timer_count;
wire timer_en;                  // On pausing, that is, en = 0, timer should hold its state
wire timer_load;                // Used to set the desired countdown value (involves both sw[15:10] and sw[2])
/******************* END UPDATE ******************/


/******** UPDATE THIS SECTION ********/
/******* INITIALIZE STOPWATCH AND TIMER MODULE ***********/
// Control signals
wire mode   = sw[0];                    // 0 = stopwatch, 1 = timer
wire run    = sw[1];                    // 0 = pause (circuit holds it state), 1 = run (counter increments/decrements)
wire load   = sw[2];                    // 1 = load timer value from load_value into timer counter, 0 = do nothing
// wire [7:0] = sw[9:3] // other 7 blank switches?
wire [5:0] load_value = sw[15:10];      // Set Timer Value (Value to load in timer)
                                        //  ---> Ex. load_value = 30. Sets the timer to count down from 30s
                                        //  To load a value into counter (Zet desired laod value = sw[15:10], hit "Confirm" = sw[2]):
                                        //      - set number on the six switches of "load_value" = desired starting value) signal(sw[15:10])
                                        //      - briefly set "load" = 1 (sw[2]) (Synchronously updates FF states in counter to load_value)
                                        //          |_> Then flip load swtich (sw[2]) back to 0!
/*********************** END UPDATE **********************/

// Derived enable/load signals
assign stopwatch_en = (~mode) & run;        // Stopwatch only runs in stopwatch mode
                                            //      ---> sw0(mode) = down, sw1(run) = up
                                            //        |__ So en = ~mode & run (where run = sw[1])
                                            
assign timer_en     = mode & run;           // Timer only runs in timer mode
                                            //      ---> sw0(mode) = up, sw1(run) = up
assign timer_load   = mode & load;          // Timer only loads in timer mode
                                            //      ---> sw0(mode) = up, sw2(load) = up

//Stopwatch Module Instance
//Use "clk_1Hz" as clock signal to stopwatch and timer modules
stopwatch  stopwatch_inst(                  // LHS = submodule variables
    .clk(clk_1Hz),                          //
    .rst(btnC),                             // Stopwatch is reset to 0 value when rst = 1
    .en(stopwatch_en),                      // 
    .state(stopwatch_count)                 // 
);


//Timer Module Instance
//Use "clk_1Hz" as clock signal to stopwatch and timer modules
timer timer_inst(
    .clk(clk_1Hz),                          //
    .rst(btnC),                             // Counter is reset to 0 value when rst = 1
    .en(timer_en),                          //
    .load(timer_load),                      //
    .load_value(load_value),                //
    .state(timer_count)                     // 
);

// LED outputs
assign led[15:10]   = timer_count;          // show timer count on upper LEDs
assign led[9]       = 1'b0;                 // unconn_led9
assign led[8:3]     = stopwatch_count;      // show stopwatch count on middle LEDs
assign led[2:0]     = 3'b000;               // unconn_led

// Extra vs. basic 7-segment UI toggle below... vvv

`ifdef USE_UI_COUNT_MESSAGES
/////////////////////////////// UI EXTRA /////////////////////////////////// v
//////////////////////////////////////////////////////////////////////////
// Extra-credit display message codes
// These are interpreted by seven_segment_inf only when
// USE_SEGMENT_MESSAGES is enabled in seven_segment_inf.v.
//////////////////////////////////////////////////////////////////////////

localparam [5:0] DISP_LOAD = 6'd60;   // LOAD
localparam [5:0] DISP_SET  = 6'd61;   // SEt
localparam [5:0] DISP_UP   = 6'd62;   // UP, stopwatch/up-count mode
localparam [5:0] DISP_DN   = 6'd63;   // dn, timer/down-count mode

wire [5:0] normal_count;
assign normal_count = mode ? timer_count : stopwatch_count;


// Message timing
`ifndef SYNTHESIS
    localparam integer MSG_TICKS = 20;             // short for simulation
`else
    localparam integer MSG_TICKS = 200_000_000;    // about 2 seconds at 100 MHz
`endif

reg mode_d = 1'b0;
reg load_d = 1'b0;

reg [31:0] set_msg_cnt = 32'd0;
reg [31:0] mode_msg_cnt = 32'd0;
reg mode_msg_value = 1'b0;     // 0 = stopwatch/up mode, 1 = timer/down mode

always @(posedge clk or posedge btnC) begin
    if (btnC) begin
        mode_d <= 1'b0;
        load_d <= 1'b0;
        set_msg_cnt <= 32'd0;
        mode_msg_cnt <= 32'd0;
        mode_msg_value <= 1'b0;
    end
    else begin
        // Save previous values
        mode_d <= mode;
        load_d <= load;

        // Count down active message timers
        if (set_msg_cnt != 32'd0)
            set_msg_cnt <= set_msg_cnt - 32'd1;

        if (mode_msg_cnt != 32'd0)
            mode_msg_cnt <= mode_msg_cnt - 32'd1;

        // Detect mode switch
        if (mode != mode_d) begin
            mode_msg_cnt <= MSG_TICKS;
            mode_msg_value <= mode;
        end

        // Detect load release while in timer mode: load 1 -> 0
        if (mode && load_d && !load) begin
            set_msg_cnt <= MSG_TICKS;
        end
    end
end

// Display override priority:
// LOAD while timer load is held.
// Then SEt briefly after load is released.
// Then UP/dn briefly after mode changes.
// Otherwise normal numeric count.
assign count = (mode && load)             ? DISP_LOAD :
               (set_msg_cnt != 32'd0)    ? DISP_SET  :
               (mode_msg_cnt != 32'd0)   ? (mode_msg_value ? DISP_DN : DISP_UP) :
                                            normal_count;
`else
/////////////////////////////// END UI EXTRA /////////////////////////////// ^

// 7-segment display multiplexer
assign count = mode ? timer_count : stopwatch_count;    // In timer mode if mode = 1, else mode = 0 and we're in stopwatch mode

`endif

endmodule

// NOTES:
//
// -- Switches
//    sw[15:10]                             = 6-bit load_value
//    sw2                                   = load/confirm timer value
//    sw1                                   = run/pause
//    sw0                                   = choose mode
//
// -- LEDs
//    led[15:10] = timer_count
//    led[8:3]   = stopwatch_count
//
// -- LED row meaning:
//    [ld15][ld14][ld13][ld12][ld11][ld10] = timer value
//    [ld9]                                = unused
//    [ld8][ld7][ld6][ld5][ld4][ld3]       = stopwatch value
//    [ld2][ld1][ld0]                      = unused
//
// -- Physical Interface
//
//    7-segment display:
//    [  tens  ][  ones  ]
//
//    LED row:
//    [ld15][ld14][ld13][ld12][ld11][ld10][ld9][ld8][ld7][ld6][ld5][ld4][ld3][ld2][ld1][ld0]
//
//    Switch row:
//    [sw15][sw14][sw13][sw12][sw11][sw10][sw9][sw8][sw7][sw6][sw5][sw4][sw3][sw2][sw1][sw0]
