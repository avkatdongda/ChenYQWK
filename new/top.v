`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/19 16:51:53
// Design Name: 
// Module Name: ethernet_top

//sim注意：
// 1）mac_test上一层中的pack_total_len更改 rst_n更改
// 2）mac_test中的IDLE跳转状态改变
// 3）mac_test中的CHECK_ARP跳转状态改变
//////////////////////////////////////////////////////////////////////////////////


module top
	(
		input          		sys_clk_p, 
		input          		sys_clk_n, 
	
		input          		rst_n,
				
		output         		e_mdc,
		inout          		e_mdio,
		output			reg	e_reset,
				
		output [3:0]   		rgmii_txd,
		output         		rgmii_txctl,
		output         		rgmii_txc,
		input  [3:0]   		rgmii_rxd,
		input          		rgmii_rxctl,
		input          		rgmii_rxc,
        output              fan
    );


wire sys_clk;
wire clk_125m;
wire clk_250m;
wire locked ;
assign fan = 1'b0;

wire  [7:0] data_to_eth;
wire        valid_to_eth;
wire  [9:0] counter_to_eth;
wire        ready_to_eth;

reg  [4:0]rst_delay;

always@(posedge sys_clk)begin
  if(!rst_n)
    rst_delay<=5'd0;
  else 
    rst_delay<=rst_delay+5'd1;
end

always@(posedge sys_clk)begin
  if(!rst_n)
    e_reset<= 1'd0;
  else if(rst_delay==5'd19) 
    e_reset<= 1'd1;
  else
    e_reset<= e_reset;
end

clk_wiz_0 pll_inst
   (
    // Clock out ports
    .clk_out1(sys_clk),     // output clk_out1
    .clk_out2(clk_125m),    // clk_125m
    .clk_out3(clk_250m),    // clk_250m
    .reset(~rst_n), // input reset
    // Status and control signals
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1_p(sys_clk_p),    // input clk_in1_p
    .clk_in1_n(sys_clk_n));    // input clk_in1_n


// ethernet_test#
// (
//	 .MAC_ADDR (48'h00_0a_35_01_fe_c2),
//	 .IP_ADDR  (32'hc0a80007)
// )
ethernet_test eth1
 (
  .rst_n         (locked      ),
  .sys_clk 	     (sys_clk 	  ),
  .led 	     ( 	  ),
  .e_mdc         (e_mdc      ),
  .e_mdio        (e_mdio     ),
  .rgmii_txd     (rgmii_txd  ),
  .rgmii_txctl   (rgmii_txctl),
  .rgmii_txc     (rgmii_txc  ),
  .rgmii_rxd     (rgmii_rxd  ),
  .rgmii_rxctl   (rgmii_rxctl),
  .rgmii_rxc     (rgmii_rxc  ),
  
  .gmii_tx_clk   (),
  .data_to_eth (data_to_eth),
  .valid_to_eth (valid_to_eth),
  .counter_to_eth (counter_to_eth),  
  .ready_to_eth (ready_to_eth)
 );




data_pack u_data_pack
(
.clk_250m (clk_250m),
.clk_125m (clk_125m),
.rst_n (locked),
.data_to_eth (data_to_eth),
.valid_to_eth (valid_to_eth),
.counter_to_eth (counter_to_eth),
.ready_to_eth (ready_to_eth)
);


	
endmodule
