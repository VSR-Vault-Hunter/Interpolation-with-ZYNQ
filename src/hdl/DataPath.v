`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/15 19:38:35
// Design Name: 
// Module Name: DataPath
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


module DataPath #(parameter dataWidth = 8) (
    input   [dataWidth - 1 : 0]     din,
    input                           sclk,
    input                           aclk,
    input                           rst,
    input                           sel0,
    input                           sel1,

    input                           sfifo0_ce,
    input                           sfifo1_ce,  

    input                           afifo0_wr_en,    
    input                           afifo0_rd_en,    
    output                          afifo0_full,    
    output                          afifo0_empty,    
    input                           afifo0_rst, 
    output                          afifo0_wr_rst_busy,    
    output                          afifo0_rd_rst_busy,
    output   [dataWidth - 1 : 0]    afifo0_out,
        
    input                           afifo1_wr_en,    
    input                           afifo1_rd_en,    
    output                          afifo1_full,    
    output                          afifo1_empty,
    input                           afifo1_rst,    
    output                          afifo1_wr_rst_busy,    
    output                          afifo1_rd_rst_busy,
    output   [dataWidth - 1 : 0]    afifo1_out        
    );

    // Cache the last time pixel for row interpolation
    reg [dataWidth - 1 : 0] d_last0;
    reg [dataWidth - 1 : 0] d_last1;
    reg [dataWidth - 1 : 0] din_delay;
    always @(posedge sclk) begin
        d_last0 <= din;
        d_last1 <= d_last0;
        din_delay <= din;
    end

    // Generate row intepolation pixel
    wire [dataWidth : 0] row_inte_pixel;
    assign row_inte_pixel = (din_delay + d_last1) >> 1;

    // Synchronous FIFO assignment
    wire    [dataWidth - 1 : 0] sfifo0_in;
    wire    [dataWidth - 1 : 0] sfifo0_out;
    wire    [dataWidth - 1 : 0] sfifo1_in;
    wire    [dataWidth - 1 : 0] sfifo1_out;
    wire    [dataWidth : 0]     col_inte_pixel;

    assign sfifo0_in = (sel0 == 1'b0)? d_last1 : row_inte_pixel [7 : 0];
    assign sfifo1_in = sfifo0_out;
    assign col_inte_pixel = (sfifo0_out + sfifo1_out) >> 1;     // Generate col interpolation pixel

    // Asynchronous FIFO assignment
    wire [dataWidth - 1 : 0] afifo0_in;
    wire [dataWidth - 1 : 0] afifo0_out;
    wire [dataWidth - 1 : 0] afifo1_in;
    wire [dataWidth - 1 : 0] afifo1_out;

    assign afifo0_in = col_inte_pixel[7 : 0];
    assign afifo1_in = sfifo1_out; 
    assign dout = sel1 ? afifo0_out : afifo1_out;               

    shift_fifo sfifo0 (
        .CLK(sclk),
        .CE(sfifo0_ce),
        .D(sfifo0_in),
        .Q(sfifo0_out)
    );

    shift_fifo sfifo1 (
        .CLK(sclk),
        .CE(sfifo1_ce),
        .D(sfifo1_in),                     
        .Q(sfifo1_out)
    );

    asyncLineFIFO afifo0 (
    .rst(rst | afifo0_rst),                  // input wire rst
    .wr_clk(sclk),            // input wire sclk
    .rd_clk(aclk),            // input wire aclk
    .din(afifo0_in),                  // input wire [7 : 0] din
    .wr_en(afifo0_wr_en),              // input wire afifo0_wr_en
    .rd_en(afifo0_rd_en),              // input wire afifo0_rd_en
    .dout(afifo0_out),                // output wire [7 : 0] dout
    .full(afifo0_full),                // output wire afifo0_full
    .empty(afifo0_empty),              // output wire afifo0_empty
    .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
    .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
    );

    asyncLineFIFO afifo1 (
    .rst(rst | afifo1_rst),                  // input wire rst
    .wr_clk(sclk),            // input wire sclk
    .rd_clk(aclk),            // input wire aclk
    .din(afifo1_in),                  // input wire [7 : 0] din
    .wr_en(afifo1_wr_en),              // input wire afifo1_wr_en
    .rd_en(afifo1_rd_en),              // input wire afifo1_rd_en
    .dout(afifo1_out),                // output wire [7 : 0] dout
    .full(afifo1_full),                // output wire afifo1_full
    .empty(afifo1_empty),              // output wire afifo1_empty
    .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
    .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
    );

endmodule
