#!/bin/sh
# Синтез для Lattice iCE40 HX8K: Yosys -> nextpnr
set -e
cd "$(dirname "$0")/synth"
S=../src
yosys -p "read_verilog $S/uart_baud_gen.v $S/uart_tx.v $S/uart_rx.v $S/uart_top.v; synth_ice40 -top uart_top -json uart_top.json; stat" | tee yosys.log
nextpnr-ice40 --hx8k --package ct256 --json uart_top.json --freq 32 --seed 2 --pcf-allow-unconstrained --asc uart_top.asc 2>&1 | tee nextpnr.log
