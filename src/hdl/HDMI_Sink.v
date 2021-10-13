// -----------------------------------------------------------------------------
// Author : jy_Huang
// File   : HDMI_Sink.v
// Create : 2021-09-15 16:35:26
// Revise : 2021-09-29 20:14:38
// Editor : sublime text4, tab size (2)
// -----------------------------------------------------------------------------

module HDMI_Sink (
	RefClk_200mhz, 
	aRst_n,
	pRst_n,

	TMDS_Clk_p,
	TMDS_Clk_n,
	TMDS_Data_p,
	TMDS_Data_n,
	HDMI_SDA,
	HDMI_SCL,
	HDMI_CEC,
	HDMI_HPD,
	
	RGB,
	pHSync,
	pVSync,
	pValid,
	pClk_2x

);
	input								RefClk_200mhz;
	input wire					aRst_n;			//Asynchronous reset  	#rst_n
	input wire					pRst_n;			//Synchronous reset     #rst_n
	
	(* X_INTERFACE_INFO = "digilentinc.com:interface:tmds:1.0 TMDS CLK_P" *)
    input wire TMDS_Clk_p;
    (* X_INTERFACE_INFO = "digilentinc.com:interface:tmds:1.0 TMDS CLK_N" *)
    input wire TMDS_Clk_n;
    (* X_INTERFACE_INFO = "digilentinc.com:interface:tmds:1.0 TMDS DATA_P" *)
    input wire [2 : 0] TMDS_Data_p;
    (* X_INTERFACE_INFO = "digilentinc.com:interface:tmds:1.0 TMDS DATA_N" *)
    input wire [2 : 0] TMDS_Data_n;
	

	//HDMI resoulution interface
	inout wire					HDMI_SDA;
	inout wire					HDMI_SCL;

	input wire					HDMI_CEC;
	output reg					HDMI_HPD;

	output wire	[23: 0]	RGB;
	output wire					pHSync;
	output wire					pVSync;
	output wire					pValid;
	// output wire 				o_x5pClk;
	output wire					pClk_2x;

	wire								refClk;

	//HDMI reset

	//HDMI data output interface
	wire	[23 : 0]	vid_pData;
	wire						vid_pVDE;
	wire						vid_pHSync;
	wire						vid_pVSync;
	wire						PixelClk;
	wire						aPixelClkLckd;
	wire						pLocked;
	// wire 						SerialClk;
	wire 						BilinerClk;

	// tristate I2C signal
	wire 						SDA_I;
	wire 						SDA_O;
	wire 						SDA_T;
	wire 						SCL_I;
	wire 						SCL_O;
	wire 						SCL_T;	

	assign refClk = RefClk_200mhz;

	assign RGB 		 = {vid_pData[23 : 16], vid_pData[15 : 8], vid_pData[7 : 0]};
	assign pHSync  = vid_pHSync;
	assign pVSync  = vid_pVSync;
	assign pValid  = vid_pVDE;
	// assign pClk		 = PixelClk;
	assign pClk_2x = BilinerClk;


	always @(posedge RefClk_200mhz) begin
		if ( ~pRst_n ) begin
			HDMI_HPD <= 1'b0;
		end else begin
			HDMI_HPD <= 1'b1;
		end
	end

IOBUF #(
  .DRIVE(12), 						// Specify the output drive strength
  .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
  .IOSTANDARD("DEFAULT"), // Specify the I/O standard
  .SLEW("SLOW") 					// Specify the output slew rate
) IOBUF_SDA (
  .O(SDA_I),     					// Buffer output
  .IO(HDMI_SDA),					// Buffer inout port (connect directly to top-level port)
  .I(SDA_O),     					// Buffer input
  .T(SDA_T)      					// 3-state enable input, high=input, low=output
);

IOBUF #(
  .DRIVE(12), 						// Specify the output drive strength
  .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
  .IOSTANDARD("DEFAULT"), // Specify the I/O standard
  .SLEW("SLOW") 					// Specify the output slew rate
) IOBUF_SCL (
  .O(SCL_I),     					// Buffer output
  .IO(HDMI_SCL),					// Buffer inout port (connect directly to top-level port)
  .I(SCL_O),     					// Buffer input
  .T(SCL_T)      					// 3-state enable input, high=input, low=output
);



myDVI2RGB u_dvi2rgb (
  .TMDS_Clk_p    (TMDS_Clk_p),        // input wire TMDS_Clk_p
  .TMDS_Clk_n    (TMDS_Clk_n),        // input wire TMDS_Clk_n
  .TMDS_Data_p   (TMDS_Data_p),       // input wire [2 : 0] TMDS_Data_p
  .TMDS_Data_n   (TMDS_Data_n),       // input wire [2 : 0] TMDS_Data_n
  .RefClk        (refClk),			 		  // input wire RefClk
  .aRst_n        (aRst_n),			 		  // input wire aRst_n
  .vid_pData     (vid_pData),         // output wire [23 : 0] vid_pData
  .vid_pVDE      (vid_pVDE),          // output wire vid_pVDE
  .vid_pHSync    (vid_pHSync),        // output wire vid_pHSync
  .vid_pVSync    (vid_pVSync),        // output wire vid_pVSync
  .PixelClk      (PixelClk),          // output wire PixelClk
  // .SerialClk		 (SerialClk),         // output wire SerialClk
  .BilinerClk    (BilinerClk),
  .aPixelClkLckd (aPixelClkLckd),  	  // output wire aPixelClkLckd
  .pLocked       (pLocked),           // output wire pLocked
  .SDA_I         (SDA_I),		   			  // input wire SDA_I
  .SDA_O         (SDA_O),		   			  // output wire SDA_O
  .SDA_T         (SDA_T),		   			  // output wire SDA_T
  .SCL_I         (SCL_I),		   			  // input wire SCL_I
  .SCL_O         (SCL_O),		   			  // output wire SCL_O
  .SCL_T         (SCL_T),		   			  // output wire SCL_T
  .pRst_n        (pRst_n)		   			  // input wire pRst_n
);

endmodule