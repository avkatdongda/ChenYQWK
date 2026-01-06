library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic (
    G_DATA_BITS : natural := 8
  );
  port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    baud_tick_i : in  std_logic;
    rx_i        : in  std_logic;
    data_o      : out std_logic_vector(G_DATA_BITS-1 downto 0);
    valid_o     : out std_logic
  );
end entity uart_rx;

architecture rtl of uart_rx is
  type state_t is (IDLE, START, DATA, STOP);
  signal state_r   : state_t := IDLE;
  signal bit_idx_r : natural range 0 to G_DATA_BITS-1 := 0;
  signal data_r    : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
  signal valid_r   : std_logic := '0';

begin
  data_o  <= data_r;
  valid_o <= valid_r;

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        -- 复位：清空状态与数据
        state_r   <= IDLE;
        bit_idx_r <= 0;
        data_r    <= (others => '0');
        valid_r   <= '0';
      else
        -- 默认无新数据，只有接收完整字节才拉高 valid_r
        valid_r <= '0';
        case state_r is
          when IDLE =>
            -- 空闲态：检测到起始位（RX 拉低）后进入 START
            if rx_i = '0' then
              state_r <= START;
            end if;
          when START =>
            -- 起始位确认：在节拍处再次采样确认起始位有效
            if baud_tick_i = '1' then
              if rx_i = '0' then
                -- 起始位有效，准备采样数据位
                bit_idx_r <= 0;
                state_r   <= DATA;
              else
                -- 起始位无效，返回空闲态
                state_r <= IDLE;
              end if;
            end if;
          when DATA =>
            -- 数据位采样：每个节拍采样一位，按 LSB 先行
            if baud_tick_i = '1' then
              data_r(bit_idx_r) <= rx_i;
              if bit_idx_r = G_DATA_BITS-1 then
                -- 数据位接收完成，进入停止位
                state_r <= STOP;
              else
                -- 继续采样下一位
                bit_idx_r <= bit_idx_r + 1;
              end if;
            end if;
          when STOP =>
            -- 停止位：在节拍处采样停止位并给出有效脉冲
            if baud_tick_i = '1' then
              if rx_i = '1' then
                -- 停止位有效，拉高 valid_r 通知新数据
                valid_r <= '1';
              end if;
              -- 无论停止位是否有效，都回到空闲态
              state_r <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
