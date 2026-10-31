//------------------------------------------------------------------------------
// Тестбенч    : tb_uart
// Призначення : Функціональна верифікація UART (uart_top).
//
// Що робить тестбенч:
//   * генерує CLK 32 МГц та сигнал RESET;
//   * ТЕСТ 1 (Tx + петля): подає байти на вхід передавача, лінія TxD
//     замкнена на RxD. Незалежний монітор декодує TxD за еталонною
//     швидкістю і перевіряє формат кадру (старт/дані/стоп),
//     а приймач DUT має прийняти той самий байт;
//   * ТЕСТ 2 (Rx від "іншого пристрою"): задача uart_send формує
//     кадри з ідеальною швидкістю 19200 бод (52083.33 нс/біт), тобто
//     з невеликою розбіжністю відносно DUT (19231 бод), і перевіряє,
//     що приймач правильно збирає дані;
//   * ТЕСТ 3: кадр з помилковим стоп-бітом -> очікується rx_frame_err.
//------------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_uart;

    localparam integer CLK_FREQ  = 32_000_000;
    localparam integer BAUD_RATE = 19_200;
    localparam real    CLK_PER   = 1.0e9 / CLK_FREQ;        // 32 МГц, 31.25 нс
    // Ідеальний період біта зовнішнього пристрою: 1/19200 с
    localparam real    BIT_EXT   = 1.0e9 / BAUD_RATE;       // 52083.33 нс
    // Фактичний період біта DUT: 104 * 16 * 31.25 нс = 52000 нс
    localparam real    BIT_DUT   = 104 * 16 * CLK_PER;

    // Сигнали DUT
    reg        clk      = 1'b0;
    reg        rst      = 1'b1;
    reg        tx_start = 1'b0;
    reg  [7:0] tx_data  = 8'h00;
    wire       tx_busy, tx_done, txd;
    wire       rxd;
    wire [7:0] rx_data;
    wire       rx_valid, rx_frame_err;

    // Керування лінією RxD: петля (TxD->RxD) або зовнішній пристрій
    reg        loopback = 1'b1;
    reg        ext_line = 1'b1;

    // Результат незалежного монітора лінії TxD
    reg  [7:0] mon_byte = 8'h00;

    // Захоплення результатів приймача (імпульси rx_valid/rx_frame_err короткі)
    reg  [7:0] rx_last  = 8'h00;
    integer    rx_cnt   = 0;
    integer    ferr_cnt = 0;
    integer    err_cnt  = 0;
    integer    i;

    reg  [7:0] TX_VECTORS [0:4];
    reg  [7:0] RX_VECTORS [0:3];

    //--------------------------------------------------------------------------
    // Тестований пристрій
    //--------------------------------------------------------------------------
    uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) dut (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx_busy(tx_busy), .tx_done(tx_done), .txd(txd),
        .rxd(rxd), .rx_data(rx_data),
        .rx_valid(rx_valid), .rx_frame_err(rx_frame_err)
    );

    assign rxd = loopback ? txd : ext_line;

    //--------------------------------------------------------------------------
    // Генератор тактового сигналу
    //--------------------------------------------------------------------------
    always #(CLK_PER / 2) clk = ~clk;

    //--------------------------------------------------------------------------
    // Незалежний монітор лінії TxD: чекає спаду, стробує в середині кожного
    // біта з періодом BIT_DUT, перевіряє старт- і стоп-біти.
    //--------------------------------------------------------------------------
    reg [7:0] mb;
    integer   k;
    always @(negedge txd) begin
        if (loopback) begin
            #(BIT_DUT / 2);
            if (txd !== 1'b0) $display("MON: start bit is not 0");
            for (k = 0; k < 8; k = k + 1) begin
                #(BIT_DUT);
                mb[k] = txd;                    // LSB first
            end
            #(BIT_DUT);
            if (txd !== 1'b1) $display("MON: stop bit is not 1");
            mon_byte = mb;
        end
    end

    //--------------------------------------------------------------------------
    // Лічильники прийнятих кадрів та помилок кадру
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rx_valid) begin
            rx_last <= rx_data;
            rx_cnt  <= rx_cnt + 1;
        end
        if (rx_frame_err)
            ferr_cnt <= ferr_cnt + 1;
    end

    //--------------------------------------------------------------------------
    // Передача байта через DUT і перевірка монітором та приймачем
    //--------------------------------------------------------------------------
    task send_via_dut(input [7:0] d);
        begin
            @(posedge clk);
            tx_data  <= d;
            tx_start <= 1'b1;
            @(posedge clk);
            tx_start <= 1'b0;
            // чекаємо кінця кадру: монітор TxD і приймач вже мають результат
            @(posedge tx_done);
            #1000;
            if (rx_last !== d || ferr_cnt != 0) begin
                $display("TEST1 FAIL: sent 0x%h, received 0x%h", d, rx_last);
                err_cnt = err_cnt + 1;
            end else if (mon_byte !== d) begin
                $display("TEST1 FAIL: TxD monitor decoded 0x%h", mon_byte);
                err_cnt = err_cnt + 1;
            end else
                $display("TEST1 OK  : 0x%h -> TxD (mon 0x%h) -> RxD -> 0x%h",
                         d, mon_byte, rx_last);
            #10000;                             // пауза між кадрами
        end
    endtask

    //--------------------------------------------------------------------------
    // Імітація зовнішнього пристрою: формування кадру 8N1 на ext_line
    //--------------------------------------------------------------------------
    task uart_send(input [7:0] d, input stop_bit);
        integer b;
        begin
            ext_line = 1'b0; #(BIT_EXT);               // старт-біт
            for (b = 0; b < 8; b = b + 1) begin
                ext_line = d[b]; #(BIT_EXT);           // дані, LSB first
            end
            ext_line = stop_bit; #(BIT_EXT);           // стоп-біт
            ext_line = 1'b1;
        end
    endtask

    //--------------------------------------------------------------------------
    // Основний сценарій
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_uart.vcd");
        $dumpvars(0, tb_uart);

        TX_VECTORS[0] = 8'h2B; TX_VECTORS[1] = 8'hE1; TX_VECTORS[2] = 8'h00;
        TX_VECTORS[3] = 8'hFF; TX_VECTORS[4] = 8'h74;
        RX_VECTORS[0] = 8'hD8; RX_VECTORS[1] = 8'h3A;
        RX_VECTORS[2] = 8'h0F; RX_VECTORS[3] = 8'hC6;

        // Скидання
        rst = 1'b1;
        #200;
        @(posedge clk);
        rst <= 1'b0;
        #1000;

        // ТЕСТ 1: передавач + петля
        $display("=== TEST 1: Tx transmit (loopback TxD->RxD) ===");
        loopback = 1'b1;
        for (i = 0; i < 5; i = i + 1)
            send_via_dut(TX_VECTORS[i]);

        // ТЕСТ 2: приймач, дані від зовнішнього пристрою
        $display("=== TEST 2: Rx receive from external device ===");
        loopback = 1'b0;
        #5000;
        for (i = 0; i < 4; i = i + 1) begin
            uart_send(RX_VECTORS[i], 1'b1);
            #1000;
            if (rx_cnt == 5 + i + 1 && rx_last === RX_VECTORS[i])
                $display("TEST2 OK  : ext 0x%h -> rx_data = 0x%h", RX_VECTORS[i], rx_last);
            else begin
                $display("TEST2 FAIL: expected 0x%h, got 0x%h", RX_VECTORS[i], rx_last);
                err_cnt = err_cnt + 1;
            end
            #3000;
        end

        // ТЕСТ 3: помилка кадру (стоп-біт = 0)
        $display("=== TEST 3: frame with bad stop bit ===");
        uart_send(8'h47, 1'b0);
        #1000;
        if (ferr_cnt == 1)
            $display("TEST3 OK  : rx_frame_err asserted");
        else begin
            $display("TEST3 FAIL: rx_frame_err not asserted");
            err_cnt = err_cnt + 1;
        end
        #20000;

        if (err_cnt == 0)
            $display("=== ALL TESTS PASSED ===");
        else
            $display("=== ERRORS: %0d ===", err_cnt);
        $timeformat(-6, 1, " us", 10);
        $display("simulation finished @%t", $realtime);
        $finish;
    end

endmodule
