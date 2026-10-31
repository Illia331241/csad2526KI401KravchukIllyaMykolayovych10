//------------------------------------------------------------------------------
// Модуль      : uart_baud_gen
// Призначення : Дільник тактової частоти для UART.
//               Формує однотактовий імпульс os_tick з частотою
//               BAUD_RATE * OVERSAMPLE (за замовчуванням 16x).
//               Передавач (Tx) відраховує 16 імпульсів на один біт,
//               приймач (Rx) використовує їх для пошуку середини біта.
//
// Приклад     : CLK_FREQ = 32 МГц, BAUD_RATE = 19200, OVERSAMPLE = 16
//               DIVISOR = round(32e6 / (19200*16)) = 104
//               фактична швидкість = 32e6 / (104*16) = 19 231 бод (+0.16 %)
//------------------------------------------------------------------------------
`timescale 1ns / 1ps

module uart_baud_gen #(
    parameter integer CLK_FREQ   = 32_000_000, // частота системного такту, Гц
    parameter integer BAUD_RATE  = 19_200,     // бажана баудова швидкість, біт/с
    parameter integer OVERSAMPLE = 16          // коефіцієнт передискретизації
) (
    input  wire clk,      // системний тактовий сигнал
    input  wire rst,      // синхронне скидання, активний 1
    output reg  os_tick   // строб тривалістю 1 такт, BAUD*OVERSAMPLE Гц
);

    // Коефіцієнт ділення з округленням до найближчого цілого
    localparam integer DIVISOR =
        (CLK_FREQ + (BAUD_RATE * OVERSAMPLE) / 2) / (BAUD_RATE * OVERSAMPLE);
    // Розрядність лічильника, достатня для значення DIVISOR-1
    localparam integer CNT_W = (DIVISOR > 1) ? $clog2(DIVISOR) : 1;

    // Лічильник тактів дільника: 0 .. DIVISOR-1
    reg [CNT_W-1:0] cnt = 0;

    initial os_tick = 1'b0;

    // Лічильник-дільник: коли досягає DIVISOR-1, обнуляється
    // і видає один імпульс os_tick.
    always @(posedge clk) begin
        if (rst) begin
            cnt     <= 0;
            os_tick <= 1'b0;
        end else if (cnt == DIVISOR - 1) begin
            cnt     <= 0;
            os_tick <= 1'b1;
        end else begin
            cnt     <= cnt + 1'b1;
            os_tick <= 1'b0;
        end
    end

endmodule
