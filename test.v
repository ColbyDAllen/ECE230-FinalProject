`timescale 1ns/1ps

module test();
    
    //Key Testbench variables
    reg [3:0] test = 0;
    reg [3:0] fail = 0;
    
    // Device Under Test (DUT) Inputs and Outputs
    reg clk;                            // Clock
    wire clk_1Hz = uut.clk_1Hz;         // Clock 1Hz (runs at 100Mhz for simulating this design)
    reg btnC;                           // Reset
    reg mode;                           // Mode of Operation
    reg run;                            // Run/Pause
    reg load;                           // Load Signal
    reg [5:0] load_value;               // Value to Load into Timer
    
    wire [5:0] stopwatch_cnt;           // Stopwatch LEDs
    wire [5:0] timer_cnt;               // Timer LEDs
    
    //DUT Outputs
    wire [3:0] an;
    wire [6:0] seg;
    
    //Unconnected Testbench Signals
    wire unconn_led9;               //Unconnected LEDs
    wire [2:0] unconn_led;          //Unconnected LEDs
    reg [6:0] unconn_sw;           //unused switches
    
    //Testbench Variables
    integer start_count, end_count, count_change;
 

    // DUT
    top uut(                    // Unit Under Test (UUT) = instance name of our top module
        .clk(clk),
        .btnC(btnC),        //Reset
        .sw({load_value, unconn_sw, load, run, mode}),
        .led({timer_cnt, unconn_led9, stopwatch_cnt, unconn_led}),
        .an(an),
        .seg(seg)
    );

    //For pritning time correctly
    initial begin
        $timeformat(-9, 0, " ns", 6);
    end

    // Task to advance clk by 1 cycle
    task automatic advance_clock;
    begin
        #1 clk = ~clk;
        #1 clk = ~clk;
    end
    endtask

    // Show timer states
    task automatic show_state;
    begin
        $display("T=%0t ns | mode=%b run=%b load=%b | SW=%0d | SW_CNT=%0d | TM_CNT=%0d",
                 $time, mode, run, load,
                 load_value,
                 stopwatch_cnt,     // stopwatch
                 timer_cnt);  // timer
    end
    endtask

    //Run Clock for N cycles
    task automatic run_cycles(input integer n);
        integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            advance_clock();
        end
    end
    endtask

    // TEST SEQUENCE
    initial begin
        $dumpvars(0, test);

        //Set Initial Values of all inputs to 0
        clk = 0;
        btnC = 0;
        {load_value, unconn_sw, load, run, mode} = 0;

        //TEST 1: Reset DUT Counters
        //After asserting reset, all counter should get reset to zero
        $display("Test1: System Reset");
        test = test + 1;
        #2;         //Wait 2ns
        btnC = 1;
        run_cycles(2);  //Advance 2 clock cycles
        #2;         //Wait 2ns
        btnC = 0;
        show_state();
        if (timer_cnt !== 6'd0 | stopwatch_cnt !== 6'd0) begin
            fail = fail + 1;
            $display("Test 1: Failed! Expected timer_cnt = 0,stopwatch_cnt = 0, observed timer_cnt = %b,stopwatch_cnt = %b", timer_cnt,stopwatch_cnt);
        end else 
            $display ("Test 1: Passed!");
        

        // TEST 2: Run Stopwatch
        #10;        //Wait sometime before starting testcase
        $display("Test2: Stopwatch run: Run for 8 cycles");
        test = test + 1;
        show_state();
        start_count = stopwatch_cnt;
        mode = 0; // mode = stopwatch
        run = 1; // run
        run_cycles(8);  //Run for 8 clock cycles, that is, counter increments by 8
        show_state();
        end_count = stopwatch_cnt;
        count_change = end_count - start_count;
        if (count_change === 8) begin
            $display("Test 2: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test 2: Failed! Expected stopwatch_cnt = 7, observed stopwatch_cnt = %0d", end_count );
        end

        // TEST 3: Pause Stopwatch
        #10;        //Wait sometime before starting testcase
        $display("Test3: Stopwatch pause: Pause for 5 cycles");
        test = test + 1;
        show_state();
        start_count = stopwatch_cnt;
        run = 0; // pause
        run_cycles(5);  //Run for 5 clock cycles. As the counter is paused, the state of counter doesnot change
        show_state();
        end_count = stopwatch_cnt;
        count_change = end_count - start_count;
        if (count_change === 0) begin
            $display("Test3: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test3: Failed! Expected stopwatch_cnt = 8, observed stopwatch_cnt = %0d", end_count);
        end

        // TEST 4: Resume Stopwatch
        #10;        //Wait sometime before starting testcase
        $display("Test4: Stopwatch resume: Run for 5 cycles");
        test = test + 1;
        show_state();
        start_count = stopwatch_cnt;
        run = 1; // run
        run_cycles(5);  //Run for 5 clock cycles
        show_state();
        end_count = stopwatch_cnt;
        count_change = end_count - start_count;
        if (count_change === 5) begin       //The last testcase brought the count to 7. Count should get incremented by 5 to 13
            $display("Test4: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test4: Failed! Expected stopwatch_cnt = 13, observed stopwatch_cnt = %0d", end_count);
        end


        // TEST 5: Wrap Around
        #10;        //Wait sometime before starting testcase
        $display("Test5: Stopwatch wrap: Run for 60 cycles");
        test = test + 1;
        show_state();
        start_count = stopwatch_cnt;
        mode = 0; // stopwatch mode
        run = 1; // run
        run_cycles(60);  //Run for 60 clock cycles. The counter should loop back to starting state
        show_state();
        end_count = stopwatch_cnt;
        count_change = end_count - start_count;
        if (count_change === 0) begin
            $display("Test5: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test5: Failed! Expected stopwatch_cnt = 13, observed stopwatch_cnt = %0d", end_count);
        end


        // TEST 6: Timer Load
        #10;        //Wait sometime before starting testcase
        $display("Test6: Timer load: Load value 10 into counter");
        test = test + 1;
        //reset_dut();
        show_state();
        start_count = timer_cnt;
        mode = 1; // mode = timer
        run = 0; // pause
        load_value = 6'd10; //Load Value 10
        load = 1;
        show_state();
        run_cycles(4);  //Run for 4 clock cycles
        load = 0;
        //run_cycles(10);  //Run for 10 clock cycles
        show_state();
        if (timer_cnt === 6'd10) begin
            $display("Test6: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test6: Failed! Expected timer_cnt = 10, observed timer_cnt = %0d", timer_cnt);
        end


        // TEST 7: Timer Countdown
        #10;        //Wait sometime before starting testcase
        $display("Test7: Timer countdown: Run for 5 cycles");
        test = test + 1;
        show_state();
        start_count = timer_cnt;
        run = 1; // run
        run_cycles(5);  //Run for 5 clock cycles. The timer decrements by 5
        show_state();
        end_count = timer_cnt;
        count_change = start_count - end_count;
        if (count_change === 5) begin
            $display("Test7: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test7: Failed! Expected timer_cnt = 5, observed timer_cnt = %0d", timer_cnt);
        end
        

        // TEST 8: Timer Hold at Zero
        #10;        //Wait sometime before starting testcase
        $display("Test8: Timer hold at zero after finishing countdown: Run for 20 cycles");
        test = test + 1;
        show_state();
        run_cycles(20);  //Run long enough to reach 0
        show_state();
        if (timer_cnt === 0) begin
                $display("Test8: Passed!");
        end else begin
            fail = fail + 1;
            $display("Test8: Failed! Expected timer_cnt = 0, observed timer_cnt = %0d", timer_cnt);
        end


        // TEST 9: Mode Switching
        #10;        //Wait sometime before starting testcase
        $display("Test9: Mode switch to Stopwatch: Run for 5 cycles");
        test = test + 1;
        show_state();
        mode = 0; // switch to stopwatch
        run = 1; // run
        start_count = stopwatch_cnt;
        run_cycles(5);  //Run for 5 clock cycles
        show_state();
        end_count = stopwatch_cnt;
        count_change = end_count - start_count;
        if (count_change === 5) begin
            $display("Test9:  Passed!");
        end else begin
            fail = fail + 1;
            $display("Test9: Failed! Expected stopwatch_cnt = 5, observed stopwatch_cnt = %0d", end_count);
        end

        if (fail > 0) 
            $error("Failing Testcases! Check the messages above and fix the design. Testcases Passed = %0d/9", 9 - fail); 
        else 
            $display("All Testcases Passed! Testcases Passed = %d/9", 9 - fail); 
        
        $finish;
    end

endmodule