`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2026 07:16:46 PM
// Design Name: 
// Module Name: dff
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

// D Flip-Flop with asynchronous reset 
//      -- Explicit/Alternate implementation. We only need this if DFF module needs to be it's own thing.
module dff(
    input d,
    input clk,
    input rst,
    output reg q
);

    initial begin
        q <= 1'b0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end

endmodule