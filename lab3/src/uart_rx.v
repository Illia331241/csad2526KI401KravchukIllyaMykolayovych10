//------------------------------------------------------------------------------
// Модуль      : uart_rx
// Призначення : Приймач UART, формат 8N1, передискретизація 16x.
//
// Логіка роботи:
//   1. Вхід rx пропускається через 2-тригерний синхронізатор
//      (захист від метастабільності, бо лінія асинхронна).
//   2. IDLE : чекаємо спадаючого фронту (1 -> 0) - початок старт-біта.
//   3. START: відраховуємо 8 os_tick (середина старт-біта) і повторно
//             перевіряємо лінію. Якщо 1 - це завада, повертаємось в IDLE.
//   4. DATA : кожні 16 os_tick (середина кожного біта) зчитуємо біт
//             і вдвигаємо в зсувний регістр зліва (LSB приходить першим).
//   5. STOP : через 16 os_tick перевіряємо стоп-біт. 1 - кадр коректний
//             (rx_valid = 1), 0 - помилка кадру (rx_frame_err = 1).
//------------------------------------------------------------------------------
`timescale 1ns / 1ps

module uart_rx #(
    parameter integer DATA_BITS  = 8,
    parameter integer OVERSAMPLE = 16
) (
    input  wire                 clk,          // системний такт
    input  wire                 rst,          // синхронне скидання
    input  wire                 os_tick,      // строб від uart_baud_gen
    input  wire                 rx,           // послідовний вхід RxD
    output reg  [DATA_BITS-1:0] rx_data,      // прийнятий байт
    output reg                  rx_valid,     // імпульс 1 такт: байт готовий
    output reg                  rx_frame_err  // імпульс 1 такт: невірний стоп-біт
);

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    reg [1:0] state = S_IDLE;

    // Синхронізатор асинхронного входу (2 тригери) + попереднє значення
    reg rx_meta = 1'b1, rx_sync = 1'b1, rx_prev = 1'b1;

    reg [$clog2(OVERSAMPLE)-1:0] tick_cnt = 0;   // os_tick у межах біта
    reg [$clog2(DATA_BITS)-1:0]  bit_idx  = 0;   // номер біта даних
    reg [DATA_BITS-1:0]          shreg    = 0;

    initial begin
        rx_data      = 0;
        rx_valid     = 1'b0;
        rx_frame_err = 1'b0;
    end

    // Синхронізація входу rx з доменом clk
    always @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
            rx_prev <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
            rx_prev <= rx_sync;
        end
    end

    always @(posedge clk) begin
        rx_valid     <= 1'b0;
        rx_frame_err <= 1'b0;

        if (rst) begin
            state    <= S_IDLE;
            tick_cnt <= 0;
            bit_idx  <= 0;
            shreg    <= 0;
            rx_data  <= 0;
        end else begin
            case (state)

                // Пошук спадаючого фронту старт-біта
                S_IDLE: begin
                    if (rx_prev && !rx_sync) begin
                        tick_cnt <= 0;
                        state    <= S_START;
                    end
                end

                // Перевірка старт-біта в його середині (8 os_tick)
                S_START: begin
                    if (os_tick) begin
                        if (tick_cnt == OVERSAMPLE / 2 - 1) begin
                            tick_cnt <= 0;
                            if (!rx_sync) begin
                                bit_idx <= 0;
                                state   <= S_DATA;   // справжній старт-біт
                            end else
                                state   <= S_IDLE;   // короткий імпульс-завада
                        end else
                            tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                // Зчитування 8 біт у середині кожного біта
                S_DATA: begin
                    if (os_tick) begin
                        if (tick_cnt == OVERSAMPLE - 1) begin
                            tick_cnt <= 0;
                            shreg    <= {rx_sync, shreg[DATA_BITS-1:1]};
                            if (bit_idx == DATA_BITS - 1)
                                state <= S_STOP;
                            else
                                bit_idx <= bit_idx + 1'b1;
                        end else
                            tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                // Перевірка стоп-біта
                S_STOP: begin
                    if (os_tick) begin
                        if (tick_cnt == OVERSAMPLE - 1) begin
                            tick_cnt <= 0;
                            rx_data  <= shreg;
                            if (rx_sync)
                                rx_valid     <= 1'b1;
                            else
                                rx_frame_err <= 1'b1;
                            state <= S_IDLE;
                        end else
                            tick_cnt <= tick_cnt + 1'b1;
                    end
                end

            endcase
        end
    end

endmodule
