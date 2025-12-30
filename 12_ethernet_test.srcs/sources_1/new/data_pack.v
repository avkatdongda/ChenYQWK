`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/17 09:45:18
// Design Name: 
// Module Name: data_pack
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


module data_pack(
input            clk_250m,
input            clk_125m,
input            rst_n,

output  reg [7:0]    data_to_eth,
output  reg          valid_to_eth,
output  wire [9:0]   counter_to_eth,
output  reg          ready_to_eth
    );

// ========== sim数据 ==============
wire  [15:0]    sum_index;
wire  [15:0]    diff_index;
wire            calcu_valid;
wire  [12:0]    calcu_num;   //5000个和差为一组
  
// ========== 参数定义 ==========
localparam PACKET_SIZE = 1004;       // 每包1000字节
localparam PACKETS_PER_GROUP = 20;   // 每组20包
localparam DATA_PER_PACKET = 250;    // 每包250个32位数据（1000字节×8/32）
localparam TOTAL_DATA = 5000;        // 每组5000个和差
localparam RAM_DEPTH = 256;          // RAM深度（存储250个32位数据）
localparam RAM_ADDR_WIDTH = 8;       // RAM地址宽度    

// ========== 内部信号定义 ==========
// RAM相关信号（写端口 - 250MHz）
reg        ram_wr_en;                // RAM写使能
reg [7:0]  ram_wr_addr;              // RAM写地址（0-255）
reg [31:0] ram_wr_data;              // RAM写数据

// RAM相关信号（读端口 - 125MHz）
reg [9:0]  ram_rd_addr;              // RAM读地址（0-999）
wire [7:0] ram_rd_data;              // RAM读数据
reg        ram_rd_enable;            // RAM读使能

reg [12:0] packet_data_counter;      // 当前包数据计数器（0-249）
reg [4:0]  packet_counter;           // 包计数器 (0-19)
reg        ram_wr_complete;          // RAM写完成标志
reg [7:0]  wr_idle_counter;          // WR_IDLE状态计数器
reg [9:0]  byte_counter;             // 读使用字节计数器 (1-1004)
reg        ram_rd_complete;          // RAM读完成标志

assign counter_to_eth = byte_counter;

// 状态机
reg [2:0]  wr_state;                 // 写状态机（250MHz域）
reg [2:0]  rd_state;                 // 读状态机（125MHz域）

// 写状态机定义
localparam WR_IDLE      = 3'b000;
localparam WR_COLLECT   = 3'b001;
localparam WR_WAIT_SEND = 3'b010;
localparam WR_NEXT_PACK = 3'b011;

// 读状态机定义
localparam RD_IDLE      = 3'b000;
localparam RD_WAIT      = 3'b001;
localparam RD_SEND_HDR  = 3'b010;
localparam RD_SEND_DATA = 3'b011;
localparam RD_COMPLETE  = 3'b100;

// ========== 双端口RAM实例化 ==========
// 配置：32位宽输入，8位宽输出，深度256    
pack_8_1024 u_dpram_pack (
   // 写端口（250MHz，32位宽）
  .clka(clk_250m),    // input wire clka
  .wea(ram_wr_en),      // input wire [0 : 0] wea
  .addra(ram_wr_addr),  // input wire [7 : 0] addra
  .dina(ram_wr_data),    // input wire [31 : 0] dina
  
  // 读端口（125MHz，8位宽）
  .clkb(clk_125m),    // input wire clkb
  .enb(ram_rd_enable),      // input wire enb
  .addrb(ram_rd_addr),  // input wire [9 : 0] addrb
  .doutb(ram_rd_data)  // output wire [7 : 0] doutb
);    
    
// ========== 250MHz时钟域逻辑（数据收集和RAM写入）==========
always @(posedge clk_250m or negedge rst_n) begin
    if (!rst_n) begin
        wr_state <= WR_IDLE;
        ram_wr_addr <= 8'hff;
        ram_wr_data <= 32'd0;
        ram_wr_en <= 1'b0;
        packet_data_counter <= 13'd0;
        ram_wr_complete <= 1'b0;
        packet_counter <= 5'd0;
        wr_idle_counter <= 8'd0;
    end else begin
        case (wr_state)
            WR_IDLE: begin
                ram_wr_en <= 1'b0;
                ram_wr_complete <= 1'b0;
                packet_data_counter <= 13'd0; 
                if (wr_idle_counter == 8'd250 ) begin
                    wr_idle_counter <= 8'd0; 
                    wr_state <= WR_COLLECT;
                end else begin
                    wr_idle_counter <= wr_idle_counter + 1'b1;
                    wr_state <= WR_IDLE;                       
                end
            end
            
            WR_COLLECT: begin
                if (calcu_valid) begin
                    ram_wr_en <= 1'b1;
                    wr_state <= WR_COLLECT;
                    ram_wr_data <= {sum_index,diff_index};
                    ram_wr_addr <= ram_wr_addr + 8'd1;
                    packet_data_counter <= packet_data_counter + 13'd1;          
                end else if(packet_data_counter == DATA_PER_PACKET) begin
                    ram_wr_en <= 1'b0;  // 检查是否收集满一个RAM（250个数据）
                    wr_state <= WR_WAIT_SEND;
                    packet_data_counter <= 13'd0;
                end else begin
                    ram_wr_en <= 1'b0;
                    wr_state <= WR_COLLECT;
                end
            end
            
            WR_WAIT_SEND: begin
                ram_wr_en <= 1'b0;
                ram_wr_complete <= 1'b1; 
                // 等待读端完成当前包的读取
                if (ram_rd_complete) 
                        wr_state <= WR_NEXT_PACK; // 准备下一包数据      
            end
            
            WR_NEXT_PACK: begin
                ram_wr_addr <= 8'hff;
                ram_wr_complete <= 1'b0;
                // 重置写地址，开始收集下一包数据 
                if(calcu_num == TOTAL_DATA) begin
                   packet_counter <= 5'd0;
                   wr_state <= WR_IDLE;               
                end else begin
                   packet_counter <= packet_counter + 5'd1;
                   wr_state <= WR_COLLECT;
                end
            end
            
            default: begin
                wr_state <= WR_IDLE;
            end
        endcase
    end
end

// ========== 125MHz时钟域逻辑（数据读取和以太网发送）==========
reg [7:0]  packet_header [0:3];  // 包头部数据
reg [1:0]  hdr_byte_cnt;         // 包头字节计
 (* mark_debug="true" *) reg [3:0]  rd_wait_counter;

always @(posedge clk_125m or negedge rst_n) begin
    if (!rst_n) begin
        rd_state <= RD_IDLE;
        ram_rd_addr <= 10'd0;
        data_to_eth <= 8'd0;
        valid_to_eth <= 1'b0;
        ready_to_eth <= 1'b0;
        ram_rd_enable <= 1'b0;
        ram_rd_complete <= 1'b0;
        byte_counter <= 10'd0;
        hdr_byte_cnt <= 2'd0;
        rd_wait_counter <= 4'd0;
    end else begin
        case (rd_state)
            RD_IDLE: begin
                valid_to_eth <= 1'b0;
                ready_to_eth <= 1'b0;
                ram_rd_enable <= 1'b0;
                hdr_byte_cnt <= 2'd0; 
                // 等待RAM写入完成信号
                if (ram_wr_complete) begin
                    rd_state <= RD_WAIT; 
                    // 生成包头数据
                    packet_header[0] <= 8'h70;  // 'p'
                    if (packet_counter < 9) begin
                        packet_header[1] <= 8'h30;  // '0'
                        packet_header[2] <= 8'h30 + packet_counter + 8'h1;  // '1'-'9'
                        packet_header[3] <= 8'h20;  // 空格
                    end else if(packet_counter == 19) begin
                        packet_header[1] <= 8'h32;  // '2'
                        packet_header[2] <= 8'h30;  // '0'
                        packet_header[3] <= 8'h20;  // 空格
                    end else begin
                        packet_header[1] <= 8'h31;  // '1'
                        packet_header[2] <= 8'h30 + (packet_counter - 9);  // '0'-'9'
                        packet_header[3] <= 8'h20;  // 空格
                    end
               end
            end
            
            RD_WAIT: begin
                valid_to_eth <= 1'b0;
                ram_rd_enable <= 1'b0;
                hdr_byte_cnt <= 2'd0; 
                ready_to_eth <= 1'b1;
                if(rd_wait_counter == 4'd15) begin
                    rd_state <= RD_SEND_HDR;
                    rd_wait_counter <= 4'd0;
                end else begin
                    rd_state <= RD_WAIT;
                    rd_wait_counter <= rd_wait_counter + 1'b1;
                end
            end
            
            RD_SEND_HDR: begin
                ready_to_eth <= 1'b0;
                valid_to_eth <= 1'b1;           
                // 发送包头（4字节）
                case(hdr_byte_cnt)
                    0:begin
                         data_to_eth <= packet_header[0];
                         hdr_byte_cnt <= hdr_byte_cnt + 2'd1;
                         byte_counter <= 10'd1;
                      end
                    1:begin
                         data_to_eth <= packet_header[1];
                         hdr_byte_cnt <= hdr_byte_cnt + 2'd1;
                         byte_counter <= 10'd2;                    
                     end
                   2:begin
                         data_to_eth <= packet_header[2];
                         hdr_byte_cnt <= hdr_byte_cnt + 2'd1;
                         byte_counter <= 10'd3;
                         ram_rd_enable <= 1'b1;
                         ram_rd_addr <= 10'd0; 
                     end
                   3:begin
                        data_to_eth <= packet_header[3];
                        rd_state <= RD_SEND_DATA;
                        byte_counter <= 10'd4;  // 已经发送了4字节包头
                        ram_rd_enable <= 1'b1;
                        ram_rd_addr <= 10'd1;   // 从RAM地址0开始读取       
                    end
                endcase
            end
            
            RD_SEND_DATA: begin
                hdr_byte_cnt <= 2'd0;
                valid_to_eth <= 1'b1;
                // 从RAM读取数据并发送
                if (byte_counter < PACKET_SIZE) begin
                    data_to_eth <= ram_rd_data;                 
                    byte_counter <= byte_counter + 10'd1; // 字节计数递增 
                    // 检查是否完成当前包
                    if (byte_counter == PACKET_SIZE - 1) begin
                        rd_state <= RD_COMPLETE;
                        ram_rd_addr <= ram_rd_addr;
                        ram_rd_enable <= 1'b0;
                        ram_rd_complete <= 1'b1;
                    end else begin
                        rd_state <= RD_SEND_DATA;
                        ram_rd_enable <= 1'b1;
                        ram_rd_addr <= ram_rd_addr + 10'd1; // RAM地址递增逻辑
                        ram_rd_complete <= 1'b0;
                    end
                end
            end
            
            RD_COMPLETE: begin
                data_to_eth <= 8'd0;
                valid_to_eth <= 1'b0;
                byte_counter <= 10'd0;
                ram_rd_addr <= 10'd0;
                ram_rd_complete <= 1'b0;
                // 等待下一包或返回空闲
                if (packet_counter == PACKETS_PER_GROUP - 1 ) begin  // ||!group_active
                    rd_state <= RD_IDLE;
                end else begin
                    // 准备接收下一包
                    rd_state <= RD_IDLE;
                end
            end
            
            default: begin
                rd_state <= RD_IDLE;
            end
        endcase
    end
end

data_sim u_data_sim(
.clk_250m (clk_250m),
.rst_n (rst_n),
.sum_index (sum_index),
.diff_index (diff_index),
.calcu_valid (calcu_valid),
.calcu_num (calcu_num)
);

    
endmodule

