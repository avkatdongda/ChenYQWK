`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/17 15:45:55
// Design Name: 
// Module Name: top_sim
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


module top_sim;
reg sys_clk_p;  //200m
wire sys_clk_n;
reg rst_n;
wire e_mdc,e_mdio,e_reset;
wire [3:0] rgmii_txd;
wire rgmii_txctl,rgmii_txc;
reg  [3:0] rgmii_rxd;
reg  rgmii_rxctl;
reg  rgmii_rxc;  //125m
wire fan;

top u_top
(
.sys_clk_p (sys_clk_p),
.sys_clk_n (sys_clk_n),
.rst_n (rst_n),
.e_mdc (e_mdc),
.e_mdio (e_mdio),
.e_reset (e_reset),
.rgmii_txd (rgmii_txd),
.rgmii_txctl (rgmii_txctl),
.rgmii_rxc (rgmii_rxc),
.fan (fan)
);
   
initial begin
  sys_clk_p = 0;
  rst_n = 0;
  rgmii_rxd = 0;
  rgmii_rxctl = 0;
  rgmii_rxc = 0;
  # 300
  rst_n = 1;
end  

always #2.5 sys_clk_p = ~sys_clk_p;
always #4   rgmii_rxc = ~rgmii_rxc;    
assign      sys_clk_n = ~sys_clk_p;
   
endmodule
