set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { HDMI_CEC }]; #IO_L13N_T2_MRCC_35 Sch=hdmi_rx_cec
set_property -dict { PACKAGE_PIN P19   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_clk_n }]; #IO_L13N_T2_MRCC_34 Sch=hdmi_rx_clk_n
set_property -dict { PACKAGE_PIN N18   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_clk_p }]; #IO_L13P_T2_MRCC_34 Sch=hdmi_rx_clk_p
set_property -dict { PACKAGE_PIN W20   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_data_n[0] }]; #IO_L16N_T2_34 Sch=hdmi_rx_d_n[0]
set_property -dict { PACKAGE_PIN V20   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_data_p[0] }]; #IO_L16P_T2_34 Sch=hdmi_rx_d_p[0]
set_property -dict { PACKAGE_PIN U20   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_data_n[1] }]; #IO_L15N_T2_DQS_34 Sch=hdmi_rx_d_n[1]
set_property -dict { PACKAGE_PIN T20   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_data_p[1] }]; #IO_L15P_T2_DQS_34 Sch=hdmi_rx_d_p[1]
set_property -dict { PACKAGE_PIN P20   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_data_n[2] }]; #IO_L14N_T2_SRCC_34 Sch=hdmi_rx_d_n[2]
set_property -dict { PACKAGE_PIN N20   IOSTANDARD TMDS_33  } [get_ports { TMDS_Sink_data_p[2] }]; #IO_L14P_T2_SRCC_34 Sch=hdmi_rx_d_p[2]
set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { HDMI_HPD }]; #IO_25_34 Sch=hdmi_rx_hpd
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { HDMI_SCL }]; #IO_L11P_T1_SRCC_34 Sch=hdmi_rx_scl
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { HDMI_SDA }]; #IO_L11N_T1_SRCC_34 Sch=hdmi_rx_sda

create_clock -add -name hdmi_sink_clk -period 40.00 -waveform {0 20} [get_ports { TMDS_Sink_clk_p }];