// -----------------------------------------------------------------------------
// Author : jy_Huang
// File   : Biliner_Interpolation_Core.v
// Create : 2021-09-29 19:54:58
// Revise : 2021-10-10 19:24:46
// Editor : sublime text4, tab size (2)
// -----------------------------------------------------------------------------


module Biliner_Interpolation_Core(
	RGB,

	pHSync,
	pVSync,
	pValid,

	pClk_2x,
	ref_Clk,

	aRst_n,

	m_axis_video_aclk,
	m_axis_video_aresetn,
	m_axis_video_tdata,
	m_axis_video_tvalid,
	m_axis_video_tready,
	m_axis_video_tuser,
	m_axis_video_tlast,
	m_axis_video_tkeep
);
	
	input wire 				  aRst_n;

	input wire 					ref_Clk;

	input wire 					pClk_2x;

	input wire [23: 0]  RGB;
	input wire 				  pHSync;
	input wire 					pVSync;
	input wire 					pValid;

	input wire          m_axis_video_aclk;
	input wire          m_axis_video_aresetn;
	output wire [23:0]  m_axis_video_tdata;
	output wire         m_axis_video_tvalid;
	input wire          m_axis_video_tready;
	output wire         m_axis_video_tuser;
	output wire         m_axis_video_tlast;
	output wire [2:0]   m_axis_video_tkeep;

	wire 						sclk;
	wire 						aclk;


	// control unit ports        
	wire						input_valid;  
	wire						sel0;         
	wire						sel1;         
	wire						sfifo0_ce;
	wire						sfifo1_ce;
	wire						read_complete;
	wire						is_last_line; 
	wire	[11 : 0]	row_cnt_out;

	// data path ports
	wire 	[7 : 0]		din_r;
	wire 	[7 : 0]		din_g;
	wire 	[7 : 0]		din_b;

	wire  [7 : 0]		afifo_data_r0;
	wire  [7 : 0]		afifo_data_r1;
	wire  [7 : 0]		afifo_data_b0;
	wire  [7 : 0]		afifo_data_b1;
	wire  [7 : 0]		afifo_data_g0;
	wire  [7 : 0]		afifo_data_g1;

	wire 						afifo0_wr_en;
	wire 						afifo0_rd_en;
	wire 						afifo1_wr_en;
	wire 						afifo1_rd_en;

	wire 						r_afifo0_full;
	wire 						r_afifo0_empty;
	wire 						r_afifo1_full;
	wire 						r_afifo1_empty;

	wire 						g_afifo0_full;
	wire 						g_afifo0_empty;
	wire 						g_afifo1_full;
	wire 						g_afifo1_empty;

	wire 						b_afifo0_full;
	wire 						b_afifo0_empty;
	wire 						b_afifo1_full;
	wire 						b_afifo1_empty;

	wire 						afifo_rea_0;
	wire 						afifo_rea_1;
	wire 						afifo_empty_0;
	wire 						afifo_empty_1;
	wire 						afifo0_rst;
	wire 						afifo1_rst;

	assign sclk        = pClk_2x;
	assign aclk        = ref_Clk;
	assign input_valid = pValid;
	assign din_r       = RGB[23: 16];
	assign din_g       = RGB[15: 8];
	assign din_b       = RGB[7 : 0];

	assign read_complete	=	rd_done_sig;

	assign afifo_empty_0 = r_afifo0_empty | g_afifo0_empty | b_afifo0_empty;
	assign afifo_empty_1 = r_afifo1_empty | g_afifo1_empty | b_afifo1_empty;

	assign afifo_rea_r1 = afifo_rea_1;
	assign afifo_rea_g1 = afifo_rea_1;
	assign afifo_rea_b1 = afifo_rea_1;
	assign afifo_rea_r0 = afifo_rea_0;
	assign afifo_rea_g0 = afifo_rea_0;
	assign afifo_rea_b0 = afifo_rea_0;

ControlUnit u_interpolation_ctl
(
	.sclk          (sclk),
	.rst_n         (aRst_n),
	.input_valid   (input_valid),
	.pVSync        (pVSync),
	.sel0          (sel0),
	.sel1          (sel1),
	.sfifo0_ce     (sfifo0_ce),
	.sfifo1_ce     (sfifo1_ce),
	.read_complete (read_complete),
	.is_last_line  (is_last_line),
	.afifo0_wr_en  (afifo0_wr_en),
	.afifo1_wr_en  (afifo1_wr_en),
	.afifo0_rst    (afifo0_rst),
	.afifo1_rst    (afifo1_rst)
);


DataPath #(
	.dataWidth(8)
) r_DataPath (
	.din                (din_r),
	.sclk               (sclk),
	.aclk               (aclk),
	.rst                (~aRst_n),
	.sel0               (sel0),
	.sel1               (sel1),
	.sfifo0_ce          (sfifo0_ce),
	.sfifo1_ce          (sfifo1_ce),
	.afifo0_wr_en       (afifo0_wr_en),
	.afifo0_rd_en       (afifo_rea_r0),
	.afifo0_full        (afifo0_full),
	.afifo0_empty       (r_afifo0_empty),
	.afifo0_wr_rst_busy (afifo0_wr_rst_busy),
	.afifo0_rd_rst_busy (afifo0_rd_rst_busy),
	.afifo0_out					(afifo_data_r0),
	.afifo1_wr_en       (afifo1_wr_en),
	.afifo1_rd_en       (afifo_rea_r1),
	.afifo1_full        (afifo1_full),
	.afifo1_empty       (r_afifo1_empty),
	.afifo1_wr_rst_busy (afifo1_wr_rst_busy),
	.afifo1_rd_rst_busy (afifo1_rd_rst_busy),
	.afifo1_out					(afifo_data_r1),
	.afifo0_rst    			(afifo0_rst),
	.afifo1_rst    			(afifo1_rst)
);


DataPath #(
	.dataWidth(8)
) g_DataPath (
	.din                (din_g),
	.sclk               (sclk),
	.aclk               (aclk),
	.rst                (~aRst_n),
	.sel0               (sel0),
	.sel1               (sel1),
	.sfifo0_ce          (sfifo0_ce),
	.sfifo1_ce          (sfifo1_ce),
	.afifo0_wr_en       (afifo0_wr_en),
	.afifo0_rd_en       (afifo_rea_g0),
	.afifo0_full        (afifo0_full),
	.afifo0_empty       (g_afifo0_empty),
	.afifo0_wr_rst_busy (afifo0_wr_rst_busy),
	.afifo0_rd_rst_busy (afifo0_rd_rst_busy),
	.afifo0_out					(afifo_data_g0),
	.afifo1_wr_en       (afifo1_wr_en),
	.afifo1_rd_en       (afifo_rea_g1),
	.afifo1_full        (afifo1_full),
	.afifo1_empty       (g_afifo1_empty),
	.afifo1_wr_rst_busy (afifo1_wr_rst_busy),
	.afifo1_rd_rst_busy (afifo1_rd_rst_busy),
	.afifo1_out					(afifo_data_g1),
	.afifo0_rst    			(afifo0_rst),
	.afifo1_rst    			(afifo1_rst)
);

DataPath #(
	.dataWidth(8)
) b_DataPath (
	.din                (din_b),
	.sclk               (sclk),
	.aclk               (aclk),
	.rst                (~aRst_n),
	.sel0               (sel0),
	.sel1               (sel1),
	.sfifo0_ce          (sfifo0_ce),
	.sfifo1_ce          (sfifo1_ce),
	.afifo0_wr_en       (afifo0_wr_en),
	.afifo0_rd_en       (afifo_rea_b0),
	.afifo0_full        (afifo0_full),
	.afifo0_empty       (b_afifo0_empty),
	.afifo0_wr_rst_busy (afifo0_wr_rst_busy),
	.afifo0_rd_rst_busy (afifo0_rd_rst_busy),
	.afifo0_out					(afifo_data_b0),
	.afifo1_wr_en       (afifo1_wr_en),
	.afifo1_rd_en       (afifo_rea_b1),
	.afifo1_full        (afifo1_full),
	.afifo1_empty       (b_afifo1_empty),
	.afifo1_wr_rst_busy (afifo1_wr_rst_busy),
	.afifo1_rd_rst_busy (afifo1_rd_rst_busy),
	.afifo1_out					(afifo_data_b1),
	.afifo0_rst    			(afifo0_rst),
	.afifo1_rst    			(afifo1_rst)
);

Rerange_Pixel #(
		.BUFFER_DEPTH(2048),
		.H_pixel(1280),
		.V_line(960)
	) u_Rerange_Pixel (
		.Clk                  (aclk),
		.aRst_n               (aRst_n),
		.afifo_data_r0        (afifo_data_r0),
		.afifo_data_r1        (afifo_data_r1),
		.afifo_data_g0        (afifo_data_g0),
		.afifo_data_g1        (afifo_data_g1),
		.afifo_data_b0        (afifo_data_b0),
		.afifo_data_b1        (afifo_data_b1),
		.afifo_rea_0          (afifo_rea_0),
		.afifo_rea_1          (afifo_rea_1),
		.afifo_empty_0        (afifo_empty_0),
		.afifo_empty_1        (afifo_empty_1),
		.rd_done_sig          (rd_done_sig),
		.m_axis_video_aclk    (m_axis_video_aclk),
		.m_axis_video_aresetn (m_axis_video_aresetn),
		.m_axis_video_tdata   (m_axis_video_tdata),
		.m_axis_video_tvalid  (m_axis_video_tvalid),
		.m_axis_video_tready  (m_axis_video_tready),
		.m_axis_video_tuser   (m_axis_video_tuser),
		.m_axis_video_tlast   (m_axis_video_tlast),
		.m_axis_video_tkeep   (m_axis_video_tkeep)
	);



//biliner_ila axis_mst_ila (
//	.clk(m_axis_video_aclk), // input wire clk

//	.probe0(m_axis_video_tdata), // input wire [23:0]  probe0  
//	.probe1(m_axis_video_tvalid), // input wire [0:0]  probe1 
//	.probe2(m_axis_video_tready), // input wire [0:0]  probe2 
//	.probe3(m_axis_video_tlast), // input wire [0:0]  probe3 
//	.probe4(m_axis_video_tuser) // input wire [0:0]  probe4
//);



endmodule