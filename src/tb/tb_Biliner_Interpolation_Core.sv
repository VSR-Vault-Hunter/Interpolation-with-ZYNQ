// -----------------------------------------------------------------------------
// Author : jy_Huang
// File   : tb_Biliner_Interpolation_Core.sv
// Create : 2021-10-03 13:11:20
// Revise : 2021-10-10 15:44:45
// Editor : sublime text4, tab size (2)
// -----------------------------------------------------------------------------

`timescale 1ns/1ps



module tb_Biliner_Interpolation_Core (); /* this is automatically generated */

`define SYSCLK_PERIOD 8
`define HDMI_CLK      39.7
`define AXIS_CLK      8

  logic Clk;
  initial begin
    Clk = '0;
    forever #(`SYSCLK_PERIOD/2) Clk = ~Clk;
  end

  logic sim_HDMI_Clk;
  logic sim_HDMI_Clk_2x;
  initial begin
    sim_HDMI_Clk = '0;
    forever #(`HDMI_CLK/2) sim_HDMI_Clk = ~sim_HDMI_Clk;
  end

  initial begin
    sim_HDMI_Clk_2x = '0;
    forever #(`HDMI_CLK/4) sim_HDMI_Clk_2x = ~sim_HDMI_Clk_2x;
  end

  logic         m_axis_video_aclk;
  initial begin
    m_axis_video_aclk = '0;
    forever #(`AXIS_CLK/4) m_axis_video_aclk = ~m_axis_video_aclk;
  end
    // synchronous reset
  logic aRst_n;
  initial begin
    aRst_n <= '0;
    repeat(100)@(posedge Clk);
    aRst_n <= '1;
  end



  // (*NOTE*) replace reset, clock, others

  logic [23: 0] RGB;
  logic         pHSync;
  logic         pVSync;
  logic         pValid;
  logic         aRst_n;
  logic  [23:0] m_axis_video_tdata;
  logic         m_axis_video_tvalid;
  logic         m_axis_video_tready;
  logic         m_axis_video_tuser;
  logic         m_axis_video_tlast;
  logic   [1:0] m_axis_video_tkeep;

  Biliner_Interpolation_Core LUT
  (
    .RGB                 (RGB),
    .pHSync              (pHSync),
    .pVSync              (pVSync),
    .pValid              (pValid),
    .pClk_2x             (sim_HDMI_Clk_2x),
    .ref_Clk             (Clk),
    .aRst_n              (aRst_n),
    .m_axis_video_aclk   (m_axis_video_aclk),
    .m_axis_video_tdata  (m_axis_video_tdata),
    .m_axis_video_tvalid (m_axis_video_tvalid),
    .m_axis_video_tready (m_axis_video_tready),
    .m_axis_video_tuser  (m_axis_video_tuser),
    .m_axis_video_tlast  (m_axis_video_tlast),
    .m_axis_video_tkeep  (m_axis_video_tkeep)
  );

logic ena;

  task init();
    RGB     <= '0;
    pHSync  <= '0;
    pVSync  <= '0;
    pValid  <= '0;
    ena     <= '0;
    m_axis_video_tready <= 1'b0;
  endtask

  task drive();
    m_axis_video_tready <= 1'b1;
    ena = 1'b1;
  endtask
    
  initial begin
    // do something

    init();
    repeat(1000)@(posedge Clk);

    drive();

    wait(LUT.u_interpolation_ctl.next_state == 'hb);
    $finish;
  end

  /**********************************************************************/
/*********************  simulate VESA data format  ********************/
/**********************************************************************/

localparam H_ACTIVE = 16'd640; 
localparam H_FP     = 16'd16;      
localparam H_SYNC   = 16'd96;    
localparam H_BP     = 16'd48;      
localparam V_ACTIVE = 16'd480; 
// localparam V_FP     = 16'd10; 
localparam V_FP      = 16'd3;   
localparam V_SYNC   = 16'd2;    
// localparam V_BP     = 16'd33;
localparam V_BP      = 16'd3;    
localparam HS_POL   = 1'b1;
localparam VS_POL   = 1'b1;
localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;//horizontal total time (pixels)
localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;//vertical total time (lines)

reg         hs_reg;                     //horizontal sync register
reg         vs_reg;                     //vertical sync register
reg         hs_reg_d0;                  //delay 1 clock of 'hs_reg'
reg         vs_reg_d0;                  //delay 1 clock of 'vs_reg'
reg [11:0]  h_cnt;                      //horizontal counter
reg [11:0]  v_cnt;                      //vertical counter
reg [11:0]  active_x;                   //video x position 
reg [11:0]  active_y;                   //video y position 
reg [7:0]   rgb_r_reg;                  //video red data register
reg [7:0]   rgb_g_reg;                  //video green data register
reg [7:0]   rgb_b_reg;                  //video blue data register
reg         h_active;                   //horizontal video active
reg         v_active;                   //vertical video active
wire        video_active;               //video active(horizontal active and vertical active)
reg         video_active_d0;            //delay 1 clock of video_active

assign pHSync       = hs_reg_d0;
assign pVSync       = vs_reg_d0;
assign video_active = h_active & v_active;
assign pValid       = video_active_d0;
assign RGB          = {rgb_r_reg,rgb_g_reg,rgb_b_reg};

wire neg_video_active;

assign neg_video_active = ~video_active & video_active_d0;

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    begin
      hs_reg_d0 <= 1'b0;
      vs_reg_d0 <= 1'b0;
      video_active_d0 <= 1'b0;
    end
  else
    begin
      hs_reg_d0 <= hs_reg;
      vs_reg_d0 <= vs_reg;
      video_active_d0 <= video_active;
    end
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    h_cnt <= 12'd0;
  else if ( ena ) begin
    if(h_cnt == H_TOTAL - 1)//horizontal counter maximum value
      h_cnt <= 12'd0;
    else
      h_cnt <= h_cnt + 12'd1;
  end else 
    h_cnt <= 12'b0;
end



always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    active_x <= 12'd0;
  else if(h_cnt >= H_FP + H_SYNC + H_BP - 1)//horizontal video active
    active_x <= h_cnt - (H_FP[11:0] + H_SYNC[11:0] + H_BP[11:0] - 12'd1);
  else
    active_x <= active_x;
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    v_cnt <= 12'd0;
  else if ( ena == 1'b1 ) begin
    if(h_cnt == H_FP  - 1)//horizontal sync time
      if(v_cnt == V_TOTAL - 1)//vertical counter maximum value
        v_cnt <= 12'd0;
      else
        v_cnt <= v_cnt + 12'd1;
    else
      v_cnt <= v_cnt;
  end else 
    v_cnt <= 12'd0;
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    hs_reg <= 1'b0;
  else if(h_cnt == H_FP - 1)//horizontal sync begin
    hs_reg <= HS_POL;
  else if(h_cnt == H_FP + H_SYNC - 1)//horizontal sync end
    hs_reg <= ~hs_reg;
  else
    hs_reg <= hs_reg;
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    h_active <= 1'b0;
  else if(h_cnt == H_FP + H_SYNC + H_BP - 1)//horizontal active begin
    h_active <= 1'b1;
  else if(h_cnt == H_TOTAL - 1)//horizontal active end
    h_active <= 1'b0;
  else
    h_active <= h_active;
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    vs_reg <= !HS_POL;
  else if((v_cnt == V_FP - 1) && (h_cnt == H_FP - 1))//vertical sync begin
    vs_reg <= HS_POL;
  else if((v_cnt == V_FP + V_SYNC - 1) && (h_cnt == H_FP - 1))//vertical sync end
    vs_reg <= ~vs_reg;
  else
    vs_reg <= vs_reg;
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0)
    v_active <= 1'd0;
  else if((v_cnt == V_FP + V_SYNC + V_BP - 1) && (h_cnt == H_FP - 1))//vertical active begin
    v_active <= 1'b1;
  else if((v_cnt == V_TOTAL - 1) && (h_cnt == H_FP - 1)) //vertical active end
    v_active <= 1'b0;
  else
    v_active <= v_active;
end

always@(posedge sim_HDMI_Clk)
begin
  if(aRst_n == 1'b0) begin
    rgb_r_reg <= 8'h00;
    rgb_g_reg <= 8'h00;
    rgb_b_reg <= 8'h00;
  end else if ( video_active ) begin
    rgb_r_reg <= rgb_r_reg + 1'b1;
    rgb_g_reg <= rgb_g_reg + 1'b1;
    rgb_b_reg <= rgb_b_reg + 1'b1;
  end else begin
    rgb_r_reg <= 8'h00;
    rgb_g_reg <= 8'h00;
    rgb_b_reg <= 8'h00;
  end
end

endmodule
