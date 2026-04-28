`timescale 1ns / 1ps

module clk_div 
# (
    parameter INPUT_FREQ  = 100_000_000, // Hz
    parameter OUTPUT_FREQ = 1            // Hz (rate of enable pulse)
)
(
    input iclk,
    input rst,
    output reg  oclk   
);

// Number of cycles between pulses
localparam COUNT_MAX = INPUT_FREQ / (2*OUTPUT_FREQ);

// Ensure width is at least 1
localparam WIDTH = (COUNT_MAX > 1) ? $clog2(COUNT_MAX) : 1;

reg [WIDTH:0] count;

always @(posedge iclk) begin
    if (rst) begin
        count <= 0;
        oclk  <= 0;
    end else begin
        if (count == (COUNT_MAX - 1)) begin
            count   <= 0;
            oclk    <= ~oclk;       //Toggle after 50M cycles
        end else begin
            count <= count + 1;
        end
    end
end

endmodule