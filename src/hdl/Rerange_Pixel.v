// -----------------------------------------------------------------------------
// Author : jy_Huang
// File   : Rerange_Pixel.v
// Create : 2021-09-29 20:19:54
// Revise : 2021-10-10 18:23:20
// Editor : sublime text4, tab size (2)
// -----------------------------------------------------------------------------

module Rerange_Pixel#(
  parameter BUFFER_DEPTH = 2048,
  parameter H_pixel = 1280,
  parameter V_line  = 960
)(
	Clk,
	aRst_n,

  afifo_data_r0,
  afifo_data_r1, 
  afifo_data_g0,
  afifo_data_g1,
  afifo_data_b0,
  afifo_data_b1,
  afifo_rea_0,
  afifo_rea_1,
  afifo_empty_0,
  afifo_empty_1,

  rd_done_sig,

  m_axis_video_aclk,
  m_axis_video_aresetn,
  m_axis_video_tdata,
  m_axis_video_tvalid,
  m_axis_video_tready,
  m_axis_video_tuser,
  m_axis_video_tlast,
  m_axis_video_tkeep
);

localparam H_TOTAL = H_pixel - 1;
localparam V_TOTAL = V_line - 1;

  input               Clk;
  input               aRst_n;

  output wire         rd_done_sig;

  input wire  [7 : 0] afifo_data_r0;
  input wire  [7 : 0] afifo_data_r1; 
  input wire  [7 : 0] afifo_data_g0;
  input wire  [7 : 0] afifo_data_g1;
  input wire  [7 : 0] afifo_data_b0;
  input wire  [7 : 0] afifo_data_b1;

  output wire         afifo_rea_0;
  output wire         afifo_rea_1;
  input wire          afifo_empty_0;
  input wire          afifo_empty_1;

  // AXI4-Stream signals
  input wire          m_axis_video_aclk;     // AXI4-Stream clock
  input wire          m_axis_video_aresetn;  // AXI4-Stream reset, active low 
  output wire [23:0]  m_axis_video_tdata;    // AXI4-Stream data
  output wire         m_axis_video_tvalid;   // AXI4-Stream valid 
  input wire          m_axis_video_tready;   // AXI4-Stream ready 
  output wire         m_axis_video_tuser;    // AXI4-Stream tuser (SOF)
  output wire         m_axis_video_tlast;    // AXI4-Stream tlast (EOL)
  output wire [2:0]   m_axis_video_tkeep;    // AXI4-Stream tkeep


 	wire	[7 : 0]	pData_r;
 	wire	[7 : 0]	pData_g;
 	wire	[7 : 0]	pData_b;

  wire          is_afifo_empty;
  wire					rea_afifo;
  reg			   		sel_hor;


  reg [11 : 0] v_cnt;
  reg [11 : 0] h_cnt;

  wire         ena_count;

  reg          rd_last_line;
  reg          is_last_line;
  reg          is_last_line_d;

  wire         last_line_fifo_rea;
  wire         last_line_fifo_wea;
  wire         last_line_fifo_empty;
  wire         last_line_fifo_full;
  wire [23: 0] last_line_fifo_data_o;

  assign rd_done_sig = is_last_line;
  assign last_line_fifo_wea = rd_last_line && ~last_line_fifo_full && rea_afifo;
  assign last_line_fifo_rea = is_last_line && ~last_line_fifo_empty;

  // select afifo data channel to input 

  assign pData_r = ( sel_hor == 1'b1 ) ? afifo_data_r0 : afifo_data_r1;
  assign pData_g = ( sel_hor == 1'b1 ) ? afifo_data_g0 : afifo_data_g1;
  assign pData_b = ( sel_hor == 1'b1 ) ? afifo_data_b0 : afifo_data_b1;

  assign is_afifo_empty = ( sel_hor == 1'b0 ) ? afifo_empty_1 : afifo_empty_0 ;
  assign rea_afifo = ~is_afifo_empty && ~is_last_line;
  assign ena_count = rea_afifo;

  assign afifo_rea_0 = ( sel_hor == 1'b1 ) ? rea_afifo : 1'b0;
  assign afifo_rea_1 = ( sel_hor == 1'b0 ) ? rea_afifo : 1'b0;


  always @( posedge Clk or negedge aRst_n ) begin
    if ( aRst_n == 1'b0 ) begin
      v_cnt <= 12'b0;
    end else if ( (h_cnt == H_TOTAL) && ((ena_count == 1'b1) || (is_last_line == 1'b1)) ) begin
      if ( v_cnt == V_TOTAL ) v_cnt <= 12'b0;
      else                    v_cnt <= v_cnt + 1'b1;
    end else begin
      v_cnt <= v_cnt;
    end
  end

  always @( posedge Clk or negedge aRst_n ) begin
    if ( aRst_n == 1'b0 ) begin
      h_cnt <= 12'b0;
    end else if ( ( ena_count == 1'b1 ) || ( is_last_line == 1'b1 ) ) begin
      if ( h_cnt == H_TOTAL ) h_cnt <= 12'b0;
      else                    h_cnt <= h_cnt + 1'b1;
    end else begin
      h_cnt <= h_cnt;
    end
  end

  always @( posedge Clk or negedge aRst_n ) begin
    if ( aRst_n == 1'b0 ) begin
      sel_hor <= 1'b0;
    end
    else if ( (h_cnt == H_TOTAL) && ((ena_count == 1'b1) || (is_last_line == 1'b1)) ) begin
      sel_hor <= ~sel_hor;
    end else begin
      sel_hor <= sel_hor;
    end
  end

  always @( posedge Clk or negedge aRst_n ) begin
    if ( aRst_n == 1'b0 ) begin
      rd_last_line <= 1'b0;
    end else if ( ((ena_count == 1'b1) || (is_last_line_d == 1'b1)) && (h_cnt == H_TOTAL)) begin
      if ( v_cnt == V_TOTAL - 2 ) begin 
          rd_last_line <= 1'b1;
        end else begin
          rd_last_line <= 1'b0;
        end
      end else begin
        rd_last_line <= rd_last_line;
      end
    end

  always @( posedge Clk or negedge aRst_n ) begin
    if ( aRst_n == 1'b0 ) begin
      is_last_line <= 1'b0;
    end
    else if ( ((ena_count == 1'b1) || (is_last_line_d == 1'b1)) && (h_cnt == H_TOTAL) ) begin
      if ( v_cnt == V_TOTAL - 1 ) begin 
        is_last_line <= 1'b1;
      end else begin
        is_last_line <= 1'b0;
      end
    end else begin
      is_last_line <= is_last_line;
    end
  end

  always @( posedge Clk or negedge aRst_n ) begin
    if ( aRst_n == 1'b0 ) begin
      is_last_line_d <= 1'b0;
    end else begin
      is_last_line_d <= is_last_line;
    end
  end

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),            // String
  .ECC_MODE            ("no_ecc"),       // String
  .FIFO_MEMORY_TYPE    ("auto"),         // String
  .FIFO_READ_LATENCY   (0),              // DECIMAL
  .FIFO_WRITE_DEPTH    (BUFFER_DEPTH),   // DECIMAL
  .FULL_RESET_VALUE    (0),              // DECIMAL
  .PROG_EMPTY_THRESH   (10),             // DECIMAL
  .PROG_FULL_THRESH    (10),             // DECIMAL
  .RD_DATA_COUNT_WIDTH (1),              // DECIMAL
  .READ_DATA_WIDTH     (24),             // DECIMAL
  .READ_MODE           ("fwft"),         // String
  .SIM_ASSERT_CHK      (0),              // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_ADV_FEATURES    ("0707"),         // String
  .WAKEUP_TIME         (0),              // DECIMAL
  .WRITE_DATA_WIDTH    (24),             // DECIMAL
  .WR_DATA_COUNT_WIDTH (1)               // DECIMAL
)
last_line_fifo (
  .dout          (last_line_fifo_data_o),      
  .empty         (last_line_fifo_empty),                                                                   
  .full          (last_line_fifo_full),      
  .din           ({ afifo_data_r1, afifo_data_g1, afifo_data_b1 }),       
  .rd_en         (last_line_fifo_rea),     
  .rst           (~aRst_n),       
  .wr_clk        (Clk),    
  .wr_en         (last_line_fifo_wea),     
  .data_valid    (),                               
  .overflow      (),          
  .prog_empty    (),          
  .prog_full     (),          
  .rd_data_count (),          
  .rd_rst_busy   (),          
  .sbiterr       (),          
  .underflow     (),          
  .wr_ack        (),        
  .wr_data_count (),        
  .wr_rst_busy   (),           
  .almost_empty  (),       
  .almost_full   (),       
  .dbiterr       (),       
  .injectdbiterr (1'b0),    
  .injectsbiterr (1'b0),      
  .sleep         (1'b0)
);

wire axis_fifo_empty;
wire axis_fifo_full;
wire axis_fifo_wea;
wire axis_fifo_rea;

wire  [23 : 0]  s_axis_tdata;
wire            s_axis_tvalid;
wire            s_axis_tlast;
wire            s_axis_tuser;

assign s_axis_tdata = (is_last_line == 1'b1) ? last_line_fifo_data_o : {pData_r, pData_g, pData_b};
assign s_axis_tvalid = (is_last_line == 1'b1) ? is_last_line : ena_count;

assign axis_fifo_wea = ~axis_fifo_full & s_axis_tvalid;
assign axis_fifo_rea = ~axis_fifo_empty & m_axis_video_tready;
assign m_axis_video_tvalid = axis_fifo_rea;

assign m_axis_video_tkeep = 3'b111;

// always @( posedge Clk or negedge aRst_n ) begin
//   if ( aRst_n == 1'b0 ) begin
//     s_axis_tlast <= 1'b0;
//   end else if ( h_cnt == H_TOTAL ) begin
//     s_axis_tlast <= 1'b1;
//   end else begin
//     s_axis_tlast <= 1'b0;
//   end
// end

assign s_axis_tlast = (h_cnt == H_TOTAL) ? 1'b1 : 1'b0;
assign s_axis_tuser = (h_cnt == 0 && v_cnt == 0) ? 1'b1 : 1'b0;

// always @( posedge Clk or negedge aRst_n ) begin
//   if ( aRst_n == 1'b0 ) begin
//     s_axis_tuser <= 1'b0;
//   end else if ( (h_cnt == 0) && (v_cnt == 0)) begin
//     s_axis_tuser <= 1'b1;
//   end else begin
//     s_axis_tuser <= 1'b0;
//   end
// end

// biliner_ila u0_biliner_ila (
//  .clk(Clk), // input wire clk


//  .probe0(s_axis_tdata), // input wire [23:0]  probe0  
//  .probe1(s_axis_tlast), // input wire [0:0]  probe1 
//  .probe2(s_axis_tuser), // input wire [0:0]  probe2 
//  .probe3(axis_fifo_wea), // input wire [0:0]  probe3 
//  .probe4(s_axis_tvalid) // input wire [0:0]  probe4
// );


xpm_fifo_async # (

  .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (2048),     //positive integer
  .WRITE_DATA_WIDTH          (26),               //positive integer
  .WR_DATA_COUNT_WIDTH       (1),               //positive integer
  .PROG_FULL_THRESH          (10),               //positive integer
  .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
  .USE_ADV_FEATURES          ("0707"),           //string; "0000" to "1F1F"; 
  .READ_MODE                 ("fwft"),            //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (0),                //positive integer;
  .READ_DATA_WIDTH           (26),               //positive integer
  .RD_DATA_COUNT_WIDTH       (1),               //positive integer
  .PROG_EMPTY_THRESH         (10),               //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .CDC_SYNC_STAGES           (2),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;
) format2axis_fifo (

      .rst              (~aRst_n),
      .wr_clk           (Clk),
      .wr_en            (axis_fifo_wea),
      .din              ({s_axis_tdata,s_axis_tlast,s_axis_tuser}),
      .full             (axis_fifo_full),
      .rd_clk           (m_axis_video_aclk),
      .rd_en            (axis_fifo_rea),
      .dout             ({m_axis_video_tdata,m_axis_video_tlast,m_axis_video_tuser}),
      .empty            (axis_fifo_empty),
      .overflow         (),
      .prog_full        (),
      .wr_data_count    (),
      .almost_full      (),
      .wr_ack           (),
      .wr_rst_busy      (),
      .underflow        (),
      .rd_rst_busy      (),
      .prog_empty       (),
      .rd_data_count    (),
      .almost_empty     (),
      .data_valid       (),
      .sleep            (1'b0),
      .injectsbiterr    (1'b0),
      .injectdbiterr    (1'b0),
      .sbiterr          (),
      .dbiterr          ()
);

endmodule