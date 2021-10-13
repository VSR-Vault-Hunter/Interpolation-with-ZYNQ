`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/16 20:48:04
// Design Name: 
// Module Name: shift_fifo
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


module shift_fifo(
    input   CLK,
    input  [7 : 0] D,
    input   CE,
    output [7 : 0] Q
    );

    wire [7 : 0] q1;

    syncLineFIFO sr0 (
        .D(D),      // input wire [7 : 0] D
        .CLK(CLK),  // input wire CLK
        .CE(CE),    // input wire CE
        .Q(q1)      // output wire [7 : 0] Q
    );

    syncLineFIFO sr1 (
        .D(q1),      // input wire [7 : 0] D
        .CLK(CLK),  // input wire CLK
        .CE(CE),    // input wire CE
        .Q(Q)      // output wire [7 : 0] Q
    );


endmodule
