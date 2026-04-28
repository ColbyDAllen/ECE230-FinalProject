`timescale 1ns / 1ps

// Uncomment this line only if explicit dff instances are required (Must also toggle USE_EXPLICIT_DFF in stopwatch.v)
// `define USE_EXPLICIT_DFF

//Timer: Mod-60 downcounter with synchronous load
module timer(
    input clk,                      // Input clock signal
    input rst,                      // Asynchronous reset counter to 0
    input en,                       // Enable counting: 1 = count down, 0 = pause/hold state
    input load,                     // If load = 1, load counter with "load_value"
    input [5:0] load_value,         // Value to load into counter register. Counter will then start counting from this value
    // output reg [5:0] state          // 6-bits to represent the highest number 59
    output [5:0] state              // 6-bits to represent the highest number 59
);

`ifdef USE_EXPLICIT_DFF

/////////////////////////////// EXTRA /////////////////////////////////// v
    ////////////////////////////////////////////////////////////////
    // EXPLICIT Dff IMPLEMNTATION
    // Uncomment the "define USE_EXPLICIT_DFF" above to compile this path.
    ////////////////////////////////////////////////////////////////

    reg [5:0] next_state;

    // Combinational next-state logic feeding D inputs
    always @(*) begin

        // (2) load has priority over pause/run
        if (load) begin
            next_state = load_value;
        end

        // (3) pause / hold
        else if (!en) begin
            next_state = state;
        end

        // (4)/(5) run countdown
        else begin
            if (state == 6'd0)
                next_state = 6'd0;          // Hold at zero; do not wrap around
            else
                next_state = state - 6'd1;  // Count down by 1
        end
    end

    // Six ummm explicit DFFs to store our timer state
    dff ff0(.d(next_state[0]), .clk(clk), .rst(rst), .q(state[0]));
    dff ff1(.d(next_state[1]), .clk(clk), .rst(rst), .q(state[1]));
    dff ff2(.d(next_state[2]), .clk(clk), .rst(rst), .q(state[2]));
    dff ff3(.d(next_state[3]), .clk(clk), .rst(rst), .q(state[3]));
    dff ff4(.d(next_state[4]), .clk(clk), .rst(rst), .q(state[4]));
    dff ff5(.d(next_state[5]), .clk(clk), .rst(rst), .q(state[5]));

`else
/////////////////////////////// END EXTRA /////////////////////////////// ^

    /////////////////////////////////////////////////////////////////////////
    // DEFAULT SYNTHETIC Dff IMPLEMENTATION
    // This is the vrsion I first tested successfully.
    /////////////////////////////////////////////////////////////////////////

    reg [5:0] state_reg;

    assign state = state_reg;

    //////////////////////////////////////////////////////////////////////////
    // Required priority is:
    //      (1) rst = 1                         --> state becomes 0 immediately, rests timer to 0
    //      (2) rst = 0, load = 1               --> on next clock edge, load load_value into state
    //      (3) rst = 0, load = 0, en = 0       --> hold current state
    //      (4) rst = 0, load = 0, en = 1,
    //          state > 0                       --> count down by 1
    //      (5) rst = 0, load = 0, en = 1,
    //          state = 0                       --> stay at 0
    //
    // NOTE: reset beats everything, then load beats pause/run, 
    //       then enable controls countdown.
    //////////////////////////////////////////////////////////////////////////

    initial begin
        state_reg <= 6'd0;                              // Initial timer count 000000
    end
    
    // *** Synthesized D-FlipFlop. See dff.v for alternate explicit implementation***
    always @(posedge clk or posedge rst) begin      // Async reset, otherwise update on clock edge
        // (1) rst = 1
        if (rst) begin                              // rst = BtnC
            state_reg <= 6'd0;                          // Asynchronous reset
        end
        
        // (2) rst = 0, load = 1
        else if (load) begin                        // load = sw[2]
            state_reg <= load_value;                    // Synchronously load timer value
                                                    //      -- load_value = sw[15:10]
        end
        
        // (3) rst = 0, load = 0, en = 0
        else if (!en) begin                         // en = mode & run (where run = sw[1])
            state_reg <= state_reg;                         // Pause/hold current timer value
        end
        
        // rst = 0, load = 0, en = 1, state = ..?..
        else begin 
            // (5) state = 0
            if (state_reg == 6'd0) 
                state_reg <= 6'd0;                      // Hold at zero; do not wrap around
            // (4) state > 0
            else
                state_reg <= state_reg - 6'd1;              // Count down by 1
        end
    end
    
`endif
    
endmodule