#!/bin/sh
# Симуляція в Icarus Verilog + рендер осцилограм
set -e
cd "$(dirname "$0")/sim"
iverilog -g2012 -o tb_uart.vvp ../src/uart_baud_gen.v ../src/uart_tx.v ../src/uart_rx.v ../src/uart_top.v ../tb/tb_uart.v
vvp -n tb_uart.vvp
mkdir -p ../img
python3 plot_waves.py tb_uart.vcd ../img
