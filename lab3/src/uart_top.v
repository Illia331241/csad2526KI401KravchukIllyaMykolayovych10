//------------------------------------------------------------------------------
// Модуль      : uart_top
// Призначення : Верхній рівень UART: спільний дільник частоти,
//               передавач uart_tx і приймач uart_rx.
//------------------------------------------------------------------------------
`timescale 1ns / 1ps

module uart_top #(
    parameter integer CLK_FREQ  = 32_000_000,
    parameter integer BAUD_RATE = 19_200
) (
    input  wire       clk,
    input  wire       rst,
    // інтерфейс передавача
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_busy,
    output wire       tx_done,
    output wire       txd,          // лінія TxD
    // інтерфейс приймача
    input  wire       rxd,          // лінія RxD
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       rx_frame_err
);

    localparam integer OVERSAMPLE = 16;
    wire os_tick;

    // Дільник частоти: 32 МГц -> 19200*16 Гц
    uart_baud_gen #(
        .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .OVERSAMPLE(OVERSAMPLE)
    ) u_baud (
        .clk(clk), .rst(rst), .os_tick(os_tick)
    );

    // Передавач
    uart_tx #(.DATA_BITS(8), .OVERSAMPLE(OVERSAMPLE)) u_tx (
        .clk(clk), .rst(rst), .os_tick(os_tick),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(txd), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    // Приймач
    uart_rx #(.DATA_BITS(8), .OVERSAMPLE(OVERSAMPLE)) u_rx (
        .clk(clk), .rst(rst), .os_tick(os_tick),
        .rx(rxd), .rx_data(rx_data),
        .rx_valid(rx_valid), .rx_frame_err(rx_frame_err)
    );

endmodule
