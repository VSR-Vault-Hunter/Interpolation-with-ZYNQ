`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/16 21:05:22
// Design Name: 
// Module Name: ControlUnit
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


module ControlUnit(
    input                           sclk,
    input                           rst_n,        
    input                           input_valid,
    input                           pVSync,     

    output reg                      sel0,
    output reg                      sel1,         
    
    output reg                      sfifo0_ce,
    output reg                      sfifo1_ce,

    input                           read_complete, //  (high) indicate that the last line has been read
    output reg                      is_last_line,  //  (high) indicate that the line being read is the original last line

    output reg                      afifo0_wr_en,
    output                          afifo0_can_rd,   // read port can start to read a line out when over 70% of pixels in a line have been stored in the line buffer  
        
    output reg                      afifo1_wr_en,

    output reg                      afifo0_rst,
    output reg                      afifo1_rst
    );

/////////////////////////////////////////////////////////////////////////////////
//                            Controller with sclk
//                                   Begin
/////////////////////////////////////////////////////////////////////////////////
    wire    afifo1_can_rd;   // read port can start to read a line out when over 70% of pixels in a line have been stored in the line buffer  
    

    // counter used to count whether the # of pixel has reach 1280 (one line)
    reg [10 : 0] pixel_cnt;
    reg pixel_cnt_en;
    reg pixel_cnt_clr;
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_cnt <= 11'd0;
        end
        else if (pixel_cnt_clr) begin
            pixel_cnt <= 11'd0;
        end
        else if (pixel_cnt_en) begin
            pixel_cnt <= pixel_cnt + 11'd1;
        end
        else begin
            pixel_cnt <= pixel_cnt;
        end
    end

    // used to count rows 
    reg [8 : 0] row_cnt;
    reg row_cnt_en;
    reg row_cnt_clr;
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n ) begin
            row_cnt <= 9'd0;
        end
        else if (row_cnt_clr) begin
            row_cnt <= 9'd0;
        end
        else if (row_cnt_en && pixel_cnt == 11'd1279) begin
            row_cnt <= row_cnt + 9'd1;
        end
        else begin
            row_cnt <= row_cnt;
        end
    end

    // sel0 is set to be a 1 bit counter so as to sample the line in the right order 
    reg sel0_en;
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            sel0 <= 1'b0;
        end
        else if (sel0_en && pixel_cnt < 11'd1278) begin
            sel0 <= sel0 + 1'b1;
        end
        else begin
            sel0 <= 1'b0;
        end
    end

    // afifo counter
    reg [10 : 0] afifo0_cnt;
    reg afifo0_cnt_en;
    reg afifo0_cnt_clr;
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n || afifo0_cnt_clr) begin
            afifo0_cnt <= 11'd0;
        end
        else if (afifo0_cnt_en) begin
            afifo0_cnt <= afifo0_cnt + 11'd1;
        end
        else begin
            afifo0_cnt <= afifo0_cnt;
        end
    end
    assign afifo0_can_rd = afifo0_cnt >= 896;

    reg [10 : 0] afifo1_cnt;
    reg afifo1_cnt_en;
    reg afifo1_cnt_clr;
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n || afifo1_cnt_clr) begin
            afifo1_cnt <= 11'd0;
        end
        else if (afifo1_cnt_en) begin
            afifo1_cnt <= afifo1_cnt + 11'd1;
        end
        else begin
            afifo1_cnt <= afifo1_cnt;
        end
    end
    assign afifo1_can_rd = afifo1_cnt >= 896;

    

    // fsm that generate the control signals
    reg [3 : 0] current_state;
    reg [3 : 0] next_state;

    ///////////////////////////////////////////////////////////////////////////
    // s0_1: waiting for pVSync signal
    // s0: waiting for valide signal
    // s1: gap for 1 cycle
    // s2: reading the first_n and second a line
    // s3: finish reading the first_n line, waiting for the second line
    // s4: finish reading the second line, waiting for the third line 
    // s5: reading the rest line 
    // s6: waiting for next line
    // s7: finish reading line from input 
    // s8: 1 cycle delay to clear counter
    // s9: output the second line to last
    // s10: 1 cycle delay to clr counter
    // s11: waiting for last line to be read
    ///////////////////////////////////////////////////////////////////////////
    localparam  s0_1 = 4'd15,
                s0   = 4'd0, 
                s1   = 4'd1, 
                s2   = 4'd2, 
                s3   = 4'd3,
                s4   = 4'd4,
                s5   = 4'd5,
                s6   = 4'd6,
                s7   = 4'd7,
                s8   = 4'd8,
                s9   = 4'd9,
                s10  = 4'd10,
                s11  = 4'd11;


    // state reg assign
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= s0;
        end
        else begin
            current_state <= next_state;
        end
    end

    // state transfer 
    always @(*) begin
        case (current_state)
            s0_1: begin
                if (pVSync) begin
                    next_state <= s0;
                end
                else begin
                    next_state <= s0_1;
                end
            end

            s0: begin
                if (input_valid) begin
                    next_state <= s1;
                end
                else begin
                    next_state <= s0;
                end
            end 

            s1: begin
                if (input_valid) begin
                    if (row_cnt >= 10'd2 && row_cnt <= 9'd480) begin
                        next_state <= s5;
                    end 
                    else begin
                        next_state <= s2;
                    end
                end
                else begin
                    next_state <= s1;
                end
            end

            s2: begin
                if (pixel_cnt == 11'd1279) begin
                    if (row_cnt == 0) begin
                        next_state <= s3;
                    end
                    else if (row_cnt == 1) begin
                        next_state <= s4;
                    end
                    else begin
                        next_state <= s1;
                    end
                end
                else begin
                    next_state <= s2;
                end
            end

            s3: begin
                if (input_valid) begin
                    next_state <= s1;
                end
                else begin
                    next_state <= s3;
                end
            end

            s4: begin
                if (input_valid) begin
                    next_state <= s1;
                end
                else begin
                    next_state <= s4;
                end
            end

            s5: begin
                if (pixel_cnt == 11'd1279) begin
                    next_state <= s6;
                end
                else begin
                    next_state <= s5;
                end
            end

            s6: begin
                if (input_valid) begin
                    next_state <= s1;
                end
                else if (row_cnt == 9'd480) begin // last line 
                    next_state <= s7;
                end
                else begin
                    next_state <= s6;
                end
            end

            s7: begin
                if (pixel_cnt == 11'd1279) begin
                    next_state <= s8;
                end
                else begin
                    next_state <= s7;
                end
            end

            s8: begin
                next_state <= s9;
            end

            s9: begin
                if (pixel_cnt == 11'd1279) begin
                    next_state <= s10;
                end
                else begin
                    next_state <= s9;
                end
            end

            s10: begin
                if (read_complete) begin
                    next_state <= s11;
                end
                else begin
                    next_state <= s10;
                end
            end
            

            s11: begin
                next_state <= s0_1;
            end

            default: begin
                next_state <= s0_1;
            end 
        endcase
    end

    // generate control signal (output of state machine)
    always @(*) begin
        case (current_state)
            s0_1: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;

                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;    
            end

            s0: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;

                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s1: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;

                is_last_line <= 1'b0;

                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s2: begin
                pixel_cnt_en <= 1'b1;
                row_cnt_en <= 1'b1;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;


                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b1;
                sfifo0_ce <= 1'b1;
                sfifo1_ce <= 1'b1;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s3: begin
                pixel_cnt_en <= 1'b1;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b1;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s4: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b1;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b1;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s5: begin
                pixel_cnt_en <= 1'b1;
                row_cnt_en <= 1'b1;
                afifo0_cnt_en <= 1'b1;
                afifo1_cnt_en <= 1'b1;
                
                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b1;
                sfifo0_ce <= 1'b1;
                sfifo1_ce <= 1'b1;
                
                afifo0_wr_en = 1'b1;
                afifo1_wr_en = 1'b1;
            end

            s6: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b1;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b1;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b1;
                afifo1_cnt_clr <= 1'b1;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s7: begin
                pixel_cnt_en <= 1'b1;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b1;
                afifo1_cnt_en <= 1'b1;
                
                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b1;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b1;
                sfifo1_ce <= 1'b1;
                
                afifo0_wr_en = 1'b1;
                afifo1_wr_en = 1'b1;
            end

            s8: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;

                pixel_cnt_clr <= 1'b1;
                row_cnt_clr <= 1'b1;
                afifo0_cnt_clr <= 1'b1;
                afifo1_cnt_clr <= 1'b1;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s9: begin
                pixel_cnt_en <= 1'b1;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b1;
                afifo1_cnt_en <= 1'b1;
                
                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;

                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b1;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b1;
                sfifo1_ce <= 1'b1;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b1;
            end

            s10: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b0;

                pixel_cnt_clr <= 1'b1;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b1;
                afifo1_cnt_clr <= 1'b1;
                afifo0_rst <= 1'b0;
                afifo1_rst <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            s11: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;
                
                is_last_line <= 1'b1;
                
                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b1;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;
                afifo0_rst <= 1'b1;
                afifo1_rst <= 1'b1;

                sel1 <= 1'b1;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end

            default: begin
                pixel_cnt_en <= 1'b0;
                row_cnt_en <= 1'b0;
                afifo0_cnt_en <= 1'b0;
                afifo1_cnt_en <= 1'b0;

                is_last_line <= 1'b0;
                
                pixel_cnt_clr <= 1'b0;
                row_cnt_clr <= 1'b0;
                afifo0_cnt_clr <= 1'b0;
                afifo1_cnt_clr <= 1'b0;

                sel1 <= 1'b0;
                sel0_en <= 1'b0;
                sfifo0_ce <= 1'b0;
                sfifo1_ce <= 1'b0;
                
                afifo0_wr_en = 1'b0;
                afifo1_wr_en = 1'b0;
            end
        endcase
    end

/////////////////////////////////////////////////////////////////////////////////
//                                     End
//                            Controller with sclk                                   
/////////////////////////////////////////////////////////////////////////////////

endmodule
