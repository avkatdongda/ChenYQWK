`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/17 09:46:10
// Design Name: 
// Module Name: data_sim
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


module data_sim(
   input                clk_250m,
   input                rst_n,
   output  reg  [15:0]  sum_index,
   output  reg  [15:0]  diff_index,
   output  reg          calcu_valid,
   output  reg  [12:0]  calcu_num  // 1-5000
    );
    
    
reg [3:0] div_cnt;  // 3分频计数器，需要2位
reg       cycle_end;
reg [1:0] s_state;  // 状态计数器
reg [12:0] idle_counter;          // IDLE状态计数器8us

localparam S_IDLE   = 2'b01;
localparam S_DATA   = 2'b10;


always @(posedge clk_250m or negedge rst_n) begin
    if (!rst_n) begin
        calcu_valid <= 1'b0;
        calcu_num  <= 13'd0;
        sum_index  <= 16'hff09;
        diff_index <= 16'hff09;
        cycle_end <= 1'b0;
        div_cnt <= 4'd0;
        idle_counter <= 13'd0;
        s_state <= S_IDLE;
    end else begin
        case(s_state)
            S_IDLE: begin
                     calcu_valid <= 1'b0;
                     cycle_end <= (calcu_num == 16'd5000)? 1:0;
                     if (idle_counter == 13'd3000 ) begin
                         idle_counter <= 13'd0; 
                         s_state <= S_DATA;
                         calcu_num <= (calcu_num == 16'd5000)? 0:calcu_num;
                     end else begin
                         idle_counter <= idle_counter + 1'b1;
                         s_state <= S_IDLE;                       
                     end
                  end
            S_DATA: begin
                     cycle_end <= 1'b0;
            // 每10个时钟周期加1（当div_cnt==9时执行）
                     if (div_cnt == 4'd9) begin
                         div_cnt <= 4'd0;
                         calcu_valid <= 1'b1;
                         sum_index  <= sum_index + 3;
                         diff_index <= diff_index + 4;
                         if (calcu_num % 250 == 249) begin
                              calcu_num  <= calcu_num + 1'b1;
                              s_state <= S_IDLE;
                         end else begin
                              calcu_num  <= calcu_num + 1'b1;
                              s_state <= S_DATA;
                         end
                     end else begin
                         div_cnt <= div_cnt + 1'b1;
                         calcu_valid <= 1'b0;
                     end
                 end
            default: s_state <= S_IDLE;
        endcase
    end                 
end
    
    
endmodule
