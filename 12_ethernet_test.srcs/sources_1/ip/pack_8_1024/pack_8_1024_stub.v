// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Wed Dec 17 15:44:47 2025
// Host        : DESKTOP-3LHJ3R7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/homework_vivado/wyb_related/12_ethernet_test/12_ethernet_test.srcs/sources_1/ip/pack_8_1024/pack_8_1024_stub.v
// Design      : pack_8_1024
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_3,Vivado 2019.1" *)
module pack_8_1024(clka, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[7:0],dina[31:0],clkb,enb,addrb[9:0],doutb[7:0]" */;
  input clka;
  input [0:0]wea;
  input [7:0]addra;
  input [31:0]dina;
  input clkb;
  input enb;
  input [9:0]addrb;
  output [7:0]doutb;
endmodule
