library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic (
    G_DATA_BITS : natural := 8
  );
  port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    baud_tick_i : in  std_logic;
    data_i      : in  std_logic_vector(G_DATA_BITS-1 downto 0);
    valid_i     : in  std_logic;
    ready_o     : out std_logic;
    tx_o        : out std_logic
  );
end entity uart_tx;

architecture rtl of uart_tx is
  type state_t is (IDLE, START, DATA, STOP);
  signal state_r    : state_t := IDLE;
  signal bit_idx_r  : natural range 0 to G_DATA_BITS-1 := 0;
  signal shift_r    : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');
  signal tx_r       : std_logic := '1';
  signal ready_r    : std_logic := '1';

begin
  tx_o    <= tx_r;
  ready_o <= ready_r;

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        -- 复位：清空状态与输出，TX 线保持空闲高电平
        state_r   <= IDLE;
        bit_idx_r <= 0;
        shift_r   <= (others => '0');
        tx_r      <= '1';
        ready_r   <= '1';
      else
        case state_r is
          when IDLE =>
            -- 空闲态：等待上层拉高 valid_i 发送新字节
            tx_r    <= '1';
            ready_r <= '1';
            if valid_i = '1' then
              -- 锁存待发送数据，准备进入起始位
              shift_r   <= data_i;
              bit_idx_r <= 0;
              state_r   <= START;
              ready_r   <= '0';
            end if;
          when START =>
            -- 起始位：在波特率节拍到来时拉低 TX
            if baud_tick_i = '1' then
              tx_r    <= '0';
              state_r <= DATA;
            end if;
          when DATA =>
            -- 数据位：每个节拍发送一位，按 LSB 先行
            if baud_tick_i = '1' then
              tx_r <= shift_r(bit_idx_r);
              if bit_idx_r = G_DATA_BITS-1 then
                -- 最后一位发送完成，进入停止位
                state_r <= STOP;
              else
                -- 继续发送下一位
                bit_idx_r <= bit_idx_r + 1;
              end if;
            end if;
          when STOP =>
            -- 停止位：在节拍到来时拉高 TX，并回到空闲态
            if baud_tick_i = '1' then
              tx_r    <= '1';
              state_r <= IDLE;
              ready_r <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
