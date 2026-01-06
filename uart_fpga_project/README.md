# UART FPGA Project (VHDL)

A minimal UART (串口) communication project written in VHDL. It includes a baud generator, TX, RX, a simple loopback top module, and a basic testbench.

## Features
- 8-N-1 UART (8 data bits, no parity, 1 stop bit)
- Configurable system clock and baud rate via generics
- Ready/valid style TX interface
- RX data valid pulse

## Directory structure
```
uart_fpga_project/
  src/
    baud_gen.vhd
    uart_tx.vhd
    uart_rx.vhd
    uart_top.vhd
  sim/
    tb_uart_top.vhd
```

## How to use
1. Synthesize `src/uart_top.vhd` as the top module.
2. Connect `uart_rx_i` to your FPGA RX pin and `uart_tx_o` to your FPGA TX pin.
3. Adjust generics as needed:
   - `G_CLK_FREQ` (Hz)
   - `G_BAUD_RATE` (bps)

## Notes
- The top module loops RX data back to TX for quick bring-up.
- For integration into a larger design, use `uart_tx` and `uart_rx` directly.

