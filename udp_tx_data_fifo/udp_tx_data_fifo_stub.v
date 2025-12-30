// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Fri Dec 12 15:27:17 2025
// Host        : DESKTOP-3LHJ3R7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/homework_vivado/wyb_related/12_ethernet_test/src/ip/udp_tx_data_fifo/udp_tx_data_fifo_stub.v
// Design      : udp_tx_data_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_4,Vivado 2019.1" *)
module udp_tx_data_fifo(clk, rst, din, wr_en, rd_en, dout, full, almost_full, 
  empty, data_count)
/* synthesis syn_black_box black_box_pad_pin="clk,rst,din[7:0],wr_en,rd_en,dout[7:0],full,almost_full,empty,data_count[11:0]" */;
  input clk;
  input rst;
  input [7:0]din;
  input wr_en;
  input rd_en;
  output [7:0]dout;
  output full;
  output almost_full;
  output empty;
  output [11:0]data_count;
endmodule
