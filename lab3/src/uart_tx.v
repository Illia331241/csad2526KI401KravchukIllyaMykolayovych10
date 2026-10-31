//------------------------------------------------------------------------------
// Модуль      : uart_tx
// Призначення : Передавач UART, формат кадру 8N1
//               (1 старт-біт 0, 8 біт даних LSB first, без парності,
//               1 стоп-біт 1). Лінія в стані спокою = 1.
//
// Автомат станів (FSM):
//   IDLE  --tx_start=1-->  START  --16 tick-->  DATA  --8 біт-->  STOP
//     ^                                                            |
//     +------------------------16 tick (tx_done=1)-----------------+
//------------------------------------------------------------------------------
`timescale 1ns / 1ps

module uart_tx #(
    parameter integer DATA_BITS  = 8,   // кількість біт даних у кадрі
    parameter integer OVERSAMPLE = 16   // скільки os_tick припадає на один біт
) (
    input  wire                 clk,      // системний такт
    input  wire                 rst,      // синхронне скидання
    input  wire                 os_tick,  // строб від uart_baud_gen
    input  wire                 tx_start, // запит на передачу (1 такт)
    input  wire [DATA_BITS-1:0] tx_data,  // байт для передачі
    output wire                 tx,       // послідовний вихід TxD
    output wire                 tx_busy,  // 1 поки йде передача
    output reg                  tx_done   // імпульс 1 такт: кадр передано
);

    // Кодування станів автомата передавача
    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    reg [1:0] state = S_IDLE;

    // Лічильник os_tick всередині одного біта (0..15)
    reg [$clog2(OVERSAMPLE)-1:0] tick_cnt = 0;
    // Номер поточного біта даних (0..7)
    reg [$clog2(DATA_BITS)-1:0]  bit_idx  = 0;
    // Зсувний регістр: захоплює tx_data на старті, зсувається вправо (LSB first)
    reg [DATA_BITS-1:0]          shreg    = 0;
    // Регістр виходу (без комбінаційних "голок" на лінії TxD)
    reg                          tx_reg   = 1'b1;

    assign tx      = tx_reg;
    assign tx_busy = (state != S_IDLE);

    initial tx_done = 1'b0;

    always @(posedge clk) begin
        tx_done <= 1'b0;                       // за замовчуванням строб неактивний

        if (rst) begin
            state    <= S_IDLE;
            tick_cnt <= 0;
            bit_idx  <= 0;
            shreg    <= 0;
            tx_reg   <= 1'b1;                  // лінія у стані спокою
        end else begin
            case (state)

                // Очікування запиту: лінія = 1
                S_IDLE: begin
                    tx_reg <= 1'b1;
                    if (tx_start) begin
                        shreg    <= tx_data;   // фіксуємо дані
                        tick_cnt <= 0;
                        state    <= S_START;
                    end
                end

                // Старт-біт: тримаємо 0 протягом 16 os_tick
                S_START: begin
                    tx_reg <= 1'b0;
                    if (os_tick) begin
                        if (tick_cnt == OVERSAMPLE - 1) begin
                            tick_cnt <= 0;
                            bit_idx  <= 0;
                            state    <= S_DATA;
                        end else
                            tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                // Біти даних: виводимо shreg[0], після кожного біта зсув
                S_DATA: begin
                    tx_reg <= shreg[0];
                    if (os_tick) begin
                        if (tick_cnt == OVERSAMPLE - 1) begin
                            tick_cnt <= 0;
                            shreg    <= {1'b0, shreg[DATA_BITS-1:1]};
                            if (bit_idx == DATA_BITS - 1)
                                state <= S_STOP;
                            else
                                bit_idx <= bit_idx + 1'b1;
                        end else
                            tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                // Стоп-біт: тримаємо 1 протягом 16 os_tick
                S_STOP: begin
                    tx_reg <= 1'b1;
                    if (os_tick) begin
                        if (tick_cnt == OVERSAMPLE - 1) begin
                            tick_cnt <= 0;
                            tx_done  <= 1'b1;
                            state    <= S_IDLE;
                        end else
                            tick_cnt <= tick_cnt + 1'b1;
                    end
                end

            endcase
        end
    end

endmodule
