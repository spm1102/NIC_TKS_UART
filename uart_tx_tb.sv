`timescale 1ns/1ps

module uart_tx_tb;

    logic clk, tick, rst_n;
    logic [7:0] tx_data;
    logic start_tx;
    logic [1:0] data_bit_num;
    logic stop_bit_num;
    logic parity_en;
    logic parity_type;
    logic cts_n;

    logic tx;
    logic tx_done;
    logic rts_n;

    // DUT instantiation
    uart_tx uut (
        .clk(clk),
        .tick(tick),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .start_tx(start_tx),
        .data_bit_num(data_bit_num),
        .stop_bit_num(stop_bit_num),
        .parity_en(parity_en),
        .parity_type(parity_type),
        .cts_n(cts_n),
        .tx(tx),
        .tx_done(tx_done),
        .rts_n(rts_n)
    );

    // Clock generator: 10ns period (100 MHz)
    always #5 clk = ~clk;

    // Tick generator: 160ns period (~baud rate)
    always #52083 tick = ~tick;

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        // Initialize
        clk = 0;
        tick = 1;
        rst_n = 0;
        start_tx = 0;
        tx_data = 8'hA5;       // 10100101
        data_bit_num = 2'b11;  // 8 bits
        stop_bit_num = 0;      // 1 stop bit
        parity_en = 1;
        parity_type = 0;       // even
        cts_n = 0;

        #50 rst_n = 1;
        #200;

        // Start transmitting
        start_tx = 1;
        #200;
        start_tx = 0;

        // Wait enough time for the full frame (START + 8 + PARITY + 1 STOP)
        // 11 bits * 16 tick per bit * 160ns = ~28us
        #18333216;

        $display("Finished sim at %t, tx_done = %b", $time, tx_done);

        #1000;
        $finish;
    end

endmodule
