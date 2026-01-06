library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_top is
end entity;

architecture sim of tb_uart_top is
  constant C_CLK_FREQ  : natural := 10_000_000; -- 10 MHz for sim
  constant C_BAUD_RATE : natural := 115200;
  constant C_CLK_PER   : time := 100 ns;

  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal rx    : std_logic := '1';
  signal tx    : std_logic;

  procedure uart_send_byte(signal rx_line : out std_logic; data : std_logic_vector(7 downto 0)) is
    constant bit_time : time := 1 sec / C_BAUD_RATE;
  begin
    rx_line <= '0';
    wait for bit_time;
    for i in 0 to 7 loop
      rx_line <= data(i);
      wait for bit_time;
    end loop;
    rx_line <= '1';
    wait for bit_time;
  end procedure;

begin
  clk <= not clk after C_CLK_PER/2;

  dut : entity work.uart_top
    generic map (
      G_CLK_FREQ  => C_CLK_FREQ,
      G_BAUD_RATE => C_BAUD_RATE,
      G_DATA_BITS => 8
    )
    port map (
      clk_i     => clk,
      rst_i     => rst,
      uart_rx_i => rx,
      uart_tx_o => tx
    );

  process
  begin
    wait for 1 us;
    rst <= '0';
    wait for 1 us;

    uart_send_byte(rx, x"55");
    wait for 2 ms;
    uart_send_byte(rx, x"A5");
    wait for 2 ms;

    wait;
  end process;

end architecture;
