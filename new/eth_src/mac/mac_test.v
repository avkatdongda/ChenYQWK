
//////////////////////////////////////////////////////////////////////////////////////
//Module Name : mac_top
//Description :
//
//////////////////////////////////////////////////////////////////////////////////////
//`define TEST_SPEED
`timescale 1 ns/1 ns
module mac_test
(
 input                rst_n  , 
 input [31:0]         pack_total_len,  
 input                gmii_tx_clk ,
 input                gmii_rx_clk ,
 input                gmii_rx_dv,
 input  [7:0]         gmii_rxd,
  (* mark_debug="true" *) output reg           gmii_tx_en,
  (* mark_debug="true" *) output reg [7:0]     gmii_txd,
 (* mark_debug="true" *) input  [7:0]         data_to_eth,
 (* mark_debug="true" *) input                valid_to_eth,
 (* mark_debug="true" *) input  [9:0]         counter_to_eth,
 (* mark_debug="true" *) input                ready_to_eth 
);

//=============== ¿çÊ±ÖÓÓò´¦Àí ===============//
reg [7:0] data_to_eth_d1,data_to_eth_d2;
reg valid_to_eth_d1,valid_to_eth_d2;
reg [9:0] counter_to_eth_d1,counter_to_eth_d2;
reg ready_to_eth_d1,ready_to_eth_d2,ready_to_eth_d3,ready_to_eth_d4;
 (* mark_debug="true" *) reg data_ready;

always @(posedge gmii_tx_clk)
begin
   data_to_eth_d1 <= data_to_eth;
   data_to_eth_d2 <= data_to_eth_d1;
   valid_to_eth_d1 <= valid_to_eth;
   valid_to_eth_d2 <= valid_to_eth_d1;
   counter_to_eth_d1 <=  counter_to_eth;
   counter_to_eth_d2 <=  counter_to_eth_d1;
   ready_to_eth_d1 <= ready_to_eth;
   ready_to_eth_d2 <= ready_to_eth_d1;
   ready_to_eth_d3 <= ready_to_eth_d2;
   ready_to_eth_d4 <= ready_to_eth_d3;
   data_ready <= ready_to_eth_d2 && ~ready_to_eth_d4;
end

reg                  gmii_rx_dv_d0 ;
reg   [7:0]          gmii_rxd_d0 ;
wire                 gmii_tx_en_tmp ;
wire   [7:0]         gmii_txd_tmp ;

 (* mark_debug="true" *)reg   [7:0]          ram_wr_data ;
 (* mark_debug="true" *)reg                  ram_wr_en ;
 (* mark_debug="true" *)wire                 udp_ram_data_req ;
reg   [15:0]         udp_send_data_length ;

wire  [7:0]          tx_ram_wr_data ;
wire                 tx_ram_wr_en ;
 (* mark_debug="true" *)wire                 udp_tx_req ;
wire                 arp_request_req ;
wire                 mac_send_end ;
 (* mark_debug="true" *)reg                  write_end ;

wire [7:0]           udp_rec_ram_rdata ;
reg  [10:0]          udp_rec_ram_read_addr ;
wire [15:0]          udp_rec_data_length ;
wire                 udp_rec_data_valid ;

wire                 udp_tx_end  ;
wire                 almost_full ;

reg                  udp_ram_wr_en ;
reg                  udp_write_end ;
wire                 write_ram_end ;
reg  [31:0]          wait_cnt ;


wire button_negedge ;

wire mac_not_exist ;
wire arp_found ;

parameter FRAME_GAP = 2750;  //22us

parameter IDLE          = 9'b000_000_001 ;  // 001
parameter ARP_REQ       = 9'b000_000_010 ;  // 002
parameter ARP_SEND      = 9'b000_000_100 ;  // 004
parameter ARP_WAIT      = 9'b000_001_000 ;  // 008
parameter GEN_REQ       = 9'b000_010_000 ;  // 010
parameter WRITE_RAM     = 9'b000_100_000 ;  // 020
parameter SEND          = 9'b001_000_000 ;  // 040
parameter WAIT          = 9'b010_000_000 ;  // 080
parameter CHECK_ARP     = 9'b100_000_000 ;  // 100


(* mark_debug="true" *) reg [8:0]    state  ;
reg [8:0]    next_state ;
reg  [15:0]  ram_cnt ;
reg    almost_full_d0 ;
reg    almost_full_d1 ;
always @(posedge gmii_tx_clk or negedge rst_n)
  begin
    if (~rst_n)
      state  <=  IDLE  ;
    else
      state  <= next_state ;
  end
  
always @(*)
  begin
    case(state)
      IDLE        :
        begin
        if (wait_cnt == pack_total_len)    
            next_state <= ARP_REQ ; //ARP_REQ WAIT
          else
            next_state <= IDLE ;
        end

      ARP_REQ     :
        next_state <= ARP_SEND ;
      ARP_SEND    :
        begin
          if (mac_send_end)
            next_state <= ARP_WAIT ;
          else
            next_state <= ARP_SEND ;
        end
      ARP_WAIT    :
        begin
          if (arp_found)
            next_state <= WAIT ;
          else if (wait_cnt == pack_total_len)
            next_state <= ARP_REQ ;
          else
            next_state <= ARP_WAIT ;
        end
      GEN_REQ     :        //010
        begin
          if (udp_ram_data_req) 
            next_state <= WRITE_RAM ;
          else
            next_state <= GEN_REQ ;
        end
      WRITE_RAM   :      // 020
        begin
          if (write_ram_end) 
            next_state <= WAIT     ;
          else
            next_state <= WRITE_RAM ;
        end
        
      SEND        :
        begin
          if (udp_tx_end)
            next_state <= WAIT ;
          else
            next_state <= SEND ;
        end
        
      WAIT        :     //080
        begin
		  `ifdef TEST_SPEED  
          if (wait_cnt == 32'd90)             //frame gap
		  `else
		  if (data_ready)    //wait_cnt == FRAME_GAP
		  `endif
            next_state <= CHECK_ARP ;
          else
            next_state <= WAIT ;
        end
      CHECK_ARP   :    //100
        begin
          if (mac_not_exist) //mac_not_exist 0
            next_state <= ARP_REQ ;
          else if (almost_full_d1)
            next_state <= CHECK_ARP ;
          else
            next_state <= GEN_REQ ;
        end
      default     :
        next_state <= IDLE ;
    endcase
  end
  
  
//assign write_ram_end        = (write_sel)? udp_write_end : write_end ;
//assign tx_ram_wr_data       = (write_sel)? udp_rec_ram_rdata : ram_wr_data ;
//assign tx_ram_wr_en         = (write_sel)? udp_ram_wr_en : ram_wr_en ;

 assign write_ram_end        =  write_end ;
 assign tx_ram_wr_data       =  ram_wr_data ;
 assign tx_ram_wr_en         =  ram_wr_en ;


always@(posedge gmii_rx_clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      begin
        gmii_rx_dv_d0 <= 1'b0 ;
        gmii_rxd_d0   <= 8'd0 ;
      end
    else
      begin
        gmii_rx_dv_d0 <= gmii_rx_dv ;
        gmii_rxd_d0   <= gmii_rxd ;
      end
  end
  
always@(posedge gmii_tx_clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      begin
        gmii_tx_en <= 1'b0 ;
        gmii_txd   <= 8'd0 ;
      end
    else
      begin
        gmii_tx_en <= gmii_tx_en_tmp ;
        gmii_txd   <= gmii_txd_tmp ;
      end
  end



  
mac_top mac_top0
(
 .gmii_tx_clk                 (gmii_tx_clk)                  ,
 .gmii_rx_clk                 (gmii_rx_clk)                  ,
 .rst_n                       (rst_n)  ,
 
 .source_mac_addr             (48'h00_0a_35_01_fe_c0)   ,       //source mac address
 .TTL                         (8'h80),
 .source_ip_addr              (32'hc0a80002),
 .destination_ip_addr         (32'hc0a80003),
 .udp_send_source_port        (16'h1f90),
 .udp_send_destination_port   (16'h1f90),
 
 .ram_wr_data                 (tx_ram_wr_data) ,
 .ram_wr_en                   (tx_ram_wr_en),
 .udp_ram_data_req            (udp_ram_data_req),
 .udp_send_data_length        (udp_send_data_length),
 .udp_tx_end                  (udp_tx_end           ),
 .almost_full                 (almost_full          ), 
 
 .udp_tx_req                  (udp_tx_req),
 .arp_request_req             (arp_request_req ),
 
 .mac_send_end                (mac_send_end),
 .mac_data_valid              (gmii_tx_en_tmp),
 .mac_tx_data                 (gmii_txd_tmp),
 .rx_dv                       (gmii_rx_dv_d0   ),
 .mac_rx_datain               (gmii_rxd_d0 ),
 
 .udp_rec_ram_rdata           (udp_rec_ram_rdata),
 .udp_rec_ram_read_addr       (udp_rec_ram_read_addr),
 .udp_rec_data_length         (udp_rec_data_length ),
 
 .udp_rec_data_valid          (udp_rec_data_valid),
 .arp_found                   (arp_found ),
 .mac_not_exist               (mac_not_exist )
) ;
              
  
always@(posedge gmii_rx_clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      begin
        almost_full_d0   <= 1'b0 ;
        almost_full_d1   <= 1'b0 ;
      end
    else
      begin
        almost_full_d0   <= almost_full ;
        almost_full_d1   <= almost_full_d0 ;
      end
  end

always@(posedge gmii_rx_clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
	   udp_send_data_length <= 16'd0 ; 
	 else 
	   udp_send_data_length <= 16'd1004 ;  //4*UDP_DEPTH  16'd1004
  end
  
  
assign udp_tx_req    = (state == GEN_REQ) ;
assign arp_request_req  = (state == ARP_REQ) ;

always@(posedge gmii_tx_clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      wait_cnt <= 0 ;
    else if ((state==IDLE||state == WAIT || state == ARP_WAIT) && state != next_state)
      wait_cnt <= 0 ;
    else if (state==IDLE||state == WAIT || state == ARP_WAIT)
      wait_cnt <= wait_cnt + 1'b1 ;
	 else
	   wait_cnt <= 0 ;
  end


//send from sim //
reg end_flag,end_flag_d1;
always@(posedge gmii_tx_clk or negedge rst_n)
   if(rst_n == 1'b0) begin
      end_flag <= 0;
      end_flag_d1 <= 0;
   end else begin
      end_flag <= (counter_to_eth_d2 == 10'd1004);
      end_flag_d1 <= end_flag;
   end
   
always@(posedge gmii_tx_clk or negedge rst_n)
  begin
    if(rst_n == 1'b0)
      begin
        write_end  <= 1'b0;
        ram_wr_data <= 0;
        ram_wr_en  <= 0 ;
      end
    else if (state == WRITE_RAM)
      begin
        if(end_flag || end_flag_d1) begin
            ram_wr_en <=1'b0;
            write_end <= 1'b1;
        end else if(valid_to_eth_d2) begin
            ram_wr_en <= 1'b1 ;
            write_end <= 1'b0 ;       
            ram_wr_data <= data_to_eth_d2;
       end else begin
           write_end  <= 1'b0;
           ram_wr_data <= 0;
           ram_wr_en  <= 0 ;
      end 
    end else begin
         write_end  <= 1'b0;
         ram_wr_data <= 0;
         ram_wr_en  <= 0 ;
    end        
 end        
  
  
endmodule