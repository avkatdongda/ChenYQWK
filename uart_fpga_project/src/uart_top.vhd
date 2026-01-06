library ieee;
use ieee.std_logic_1164.all;

entity uart_top is
  generic (
    G_CLK_FREQ  : natural := 50_000_000; -- Hz
    G_BAUD_RATE : natural := 115200;
    G_DATA_BITS : natural := 8
  );
  port (
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    uart_rx_i : in  std_logic;
    uart_tx_o : out std_logic
  );
end entity uart_top;

architecture rtl of uart_top is
  signal baud_tick : std_logic;
  signal rx_data   : std_logic_vector(G_DATA_BITS-1 downto 0);
  signal rx_valid  : std_logic;
  signal tx_ready  : std_logic;
  signal tx_valid  : std_logic := '0';
  signal tx_data   : std_logic_vector(G_DATA_BITS-1 downto 0) := (others => '0');

begin
  baud_gen_inst : entity work.baud_gen
    generic map (
      G_CLK_FREQ  => G_CLK_FREQ,
      G_BAUD_RATE => G_BAUD_RATE
    )
    port map (
      clk_i       => clk_i,
      rst_i       => rst_i,
      baud_tick_o => baud_tick
    );

  uart_rx_inst : entity work.uart_rx
    generic map (
      G_DATA_BITS => G_DATA_BITS
    )
    port map (
      clk_i       => clk_i,
      rst_i       => rst_i,
      baud_tick_i => baud_tick,
      rx_i        => uart_rx_i,
      data_o      => rx_data,
      valid_o     => rx_valid
    );

  uart_tx_inst : entity work.uart_tx
    generic map (
      G_DATA_BITS => G_DATA_BITS
    )
    port map (
      clk_i       => clk_i,
      rst_i       => rst_i,
      baud_tick_i => baud_tick,
      data_i      => tx_data,
      valid_i     => tx_valid,
      ready_o     => tx_ready,
      tx_o        => uart_tx_o
    );

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        -- 复位：清空发送有效与数据
        tx_valid <= '0';
        tx_data  <= (others => '0');
      else
        if rx_valid = '1' and tx_ready = '1' then
          -- 收到新字节且发送器空闲：立即回环发送
          tx_data  <= rx_data;
          tx_valid <= '1';
        elsif tx_valid = '1' and tx_ready = '0' then
          -- 发送器忙：保持 valid，等待下一拍被采样
          tx_valid <= '1';
        else
          -- 默认不发送
          tx_valid <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
