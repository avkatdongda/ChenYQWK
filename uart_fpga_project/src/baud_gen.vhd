library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen is
  generic (
    G_CLK_FREQ  : natural := 50_000_000; -- Hz
    G_BAUD_RATE : natural := 115200      -- bps
  );
  port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    baud_tick_o : out std_logic
  );
end entity baud_gen;

architecture rtl of baud_gen is
  function clamp_divisor(clk_freq : natural; baud : natural) return natural is
    variable div : natural;
  begin
    if baud = 0 then
      return 1;
    end if;
    div := clk_freq / baud;
    if div < 1 then
      return 1;
    end if;
    return div;
  end function;

  constant C_DIVISOR : natural := clamp_divisor(G_CLK_FREQ, G_BAUD_RATE);

  function clog2(n : natural) return natural is
    variable v : natural := 0;
    variable r : natural := 0;
  begin
    if n <= 1 then
      return 1;
    end if;
    v := n - 1;
    while v > 0 loop
      v := v / 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  constant C_CNT_W : natural := clog2(C_DIVISOR);
  signal cnt_r     : unsigned(C_CNT_W-1 downto 0) := (others => '0');
  signal tick_r    : std_logic := '0';

begin
  baud_tick_o <= tick_r;

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        -- 复位：清零分频计数器与节拍输出
        cnt_r  <= (others => '0');
        tick_r <= '0';
      else
        if cnt_r = C_DIVISOR - 1 then
          -- 计数到达分频值：产生一个时钟周期的波特率节拍
          cnt_r  <= (others => '0');
          tick_r <= '1';
        else
          -- 继续计数，节拍保持为低
          cnt_r  <= cnt_r + 1;
          tick_r <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
