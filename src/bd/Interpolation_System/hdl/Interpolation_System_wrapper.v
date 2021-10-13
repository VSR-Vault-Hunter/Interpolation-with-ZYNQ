//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Wed Oct 13 09:24:05 2021
//Host        : DESKTOP-TS6N9G3 running 64-bit major release  (build 9200)
//Command     : generate_target Interpolation_System_wrapper.bd
//Design      : Interpolation_System_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module Interpolation_System_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    HDMI_CEC,
    HDMI_HPD,
    HDMI_SCL,
    HDMI_SDA,
    TMDS_Sink_clk_n,
    TMDS_Sink_clk_p,
    TMDS_Sink_data_n,
    TMDS_Sink_data_p,
    TMDS_Source_clk_n,
    TMDS_Source_clk_p,
    TMDS_Source_data_n,
    TMDS_Source_data_p);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input HDMI_CEC;
  output HDMI_HPD;
  inout HDMI_SCL;
  inout HDMI_SDA;
  input TMDS_Sink_clk_n;
  input TMDS_Sink_clk_p;
  input [2:0]TMDS_Sink_data_n;
  input [2:0]TMDS_Sink_data_p;
  output TMDS_Source_clk_n;
  output TMDS_Source_clk_p;
  output [2:0]TMDS_Source_data_n;
  output [2:0]TMDS_Source_data_p;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire HDMI_CEC;
  wire HDMI_HPD;
  wire HDMI_SCL;
  wire HDMI_SDA;
  wire TMDS_Sink_clk_n;
  wire TMDS_Sink_clk_p;
  wire [2:0]TMDS_Sink_data_n;
  wire [2:0]TMDS_Sink_data_p;
  wire TMDS_Source_clk_n;
  wire TMDS_Source_clk_p;
  wire [2:0]TMDS_Source_data_n;
  wire [2:0]TMDS_Source_data_p;

  Interpolation_System Interpolation_System_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .HDMI_CEC(HDMI_CEC),
        .HDMI_HPD(HDMI_HPD),
        .HDMI_SCL(HDMI_SCL),
        .HDMI_SDA(HDMI_SDA),
        .TMDS_Sink_clk_n(TMDS_Sink_clk_n),
        .TMDS_Sink_clk_p(TMDS_Sink_clk_p),
        .TMDS_Sink_data_n(TMDS_Sink_data_n),
        .TMDS_Sink_data_p(TMDS_Sink_data_p),
        .TMDS_Source_clk_n(TMDS_Source_clk_n),
        .TMDS_Source_clk_p(TMDS_Source_clk_p),
        .TMDS_Source_data_n(TMDS_Source_data_n),
        .TMDS_Source_data_p(TMDS_Source_data_p));
endmodule
