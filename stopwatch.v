`timescale 1ns / 1ps

// Uncomment this line only if explicit dff instances are required (Must also toggle USE_EXPLICIT_DFF in timer.v)
// `define USE_EXPLICIT_DFF

//StopWatch: Modulo-60 Counter
module stopwatch(
    input clk,                  // Input Clock Signal
    input rst,                  // Asynchronous reset counter to 0
    input en,                   // Enable counting (1 = count, 0 = pause)
    // output reg [5:0] state      // 6-bit counter state with valid stopwatch range = 0-59
    output [5:0] state          // 6-bit counter state,  stopwatch range = 0-59

);

`ifdef USE_EXPLICIT_DFF

/////////////////////////////// EXTRA /////////////////////////////////// v
    //////////////////////////////////////////////////////////////// 
    // EXPLICIT Dff IMPLEMENTATION
    // Uncomment "define USE_EXPLICIT_DFF" above to compile this path.
    ////////////////////////////////////////////////////////////////
    
    reg [5:0] next_state;

    // Combinational next state logic so we can feed "D inputs"
    always @(*) begin
        if (en) begin
            if (state == 6'd59)
                next_state = 6'd0;
            else
                next_state = state + 6'd1;
        end
        else begin
            next_state = state;       // Paise/hold current state
        end
    end

    // Six ummm explicit DFFs to store our stopwatch/counter state
    dff ff0(.d(next_state[0]), .clk(clk), .rst(rst), .q(state[0]));
    dff ff1(.d(next_state[1]), .clk(clk), .rst(rst), .q(state[1]));
    dff ff2(.d(next_state[2]), .clk(clk), .rst(rst), .q(state[2]));
    dff ff3(.d(next_state[3]), .clk(clk), .rst(rst), .q(state[3]));
    dff ff4(.d(next_state[4]), .clk(clk), .rst(rst), .q(state[4]));
    dff ff5(.d(next_state[5]), .clk(clk), .rst(rst), .q(state[5]));

`else
/////////////////////////////// END EXTRA /////////////////////////////// ^

    /////////////////////////////////////////////////////////////////////////
    // DEFAULT SYNTHESIZED / INFERRED Dff IMPLEMENTATION
    // This is the vrsion I first tested successfully
    /////////////////////////////////////////////////////////////////////////
    
    reg [5:0] state_reg;

    assign state = state_reg;

    //////////////////////////////////////////////////////////////////////////
    // Terminal count check / logic:
    //      state == 6'd59
    //
    // Required priority is (Numbers correspond to cases below):
    //      (1) rst = 1                         --> state becomes 0 immediately
    //      (2) rst = 0, en = 0                 --> hold current state
    //      (3) rst = 0, en = 1                 --> count up
    //      (4) rst = 0, en = 1, state = 59     --> wrap to 0
    //////////////////////////////////////////////////////////////////////////
    
    initial begin       
        state_reg <= 6'd0;                          // Initial stopwatch count 000000
    end
    
    // *** Synthesized D-FlipFlop. See dff.v for alternate explicit implementation***
    always @(posedge clk or posedge rst) begin  // Setup count logic, watch for clk and reset buttons
                                                // *NOTE: Anything assigned inside an always or initial block must be 
                                                //        declared as a reg (i.e. "output reg [5:0] state ")
        // (1) rst = 1
        if (rst) begin                          
            state_reg <= 6'd0;                      // Asynchronous reset: If Reset button asserted, set counter to 000000
        end
        
        //  rst = 0, en = 1, state = ..?..
        else if (en) begin                      // If Enable button is asserted, counter runs.
            // (4) rst = 0, en = 1, state = 59
            if (state_reg == 6'd59)                 // If current state is 59, additional count resets it 000000
                state_reg <= 6'd0;
            // (3) rst = 0, en = 1 state = 0:58
            else
                state_reg <= state_reg + 6'd1;          // Otherwise if the count is between bin(0-58), we just increment by 1
        end
        
        // (2) rst = 0, en = 0
        else begin
            state_reg <= state_reg;                     // If Enable button is NOT asserted (en = 0), we just hold our state/count (i.e. "Pause")
        end
    end
    
`endif
    
endmodule