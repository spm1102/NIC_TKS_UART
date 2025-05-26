`timescale 1ns/1ps

module top_tb();

    reg clk;
    reg rst_n;
    reg [10:0] dvsr;
    reg [7:0] tx_data;
    reg start_tx;
    reg [1:0] data_bit_num;
    reg stop_bit_num;
    reg parity_en;
    reg parity_type;
    reg cts_n;

    wire tx;
    wire tx_done;
    wire rts_n;

    // Instance top module
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .dvsr(dvsr),
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

    // Clock generation 50 MHz
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20ns period
    end

    // Stimulus
    initial begin
        // Init inputs
        rst_n = 0;
        dvsr = 11'd5207; // 50 MHz / 9600 baud -1
        tx_data = 8'h00;
        start_tx = 0;
        data_bit_num = 2'b11; // ví dụ 8 bit data
        stop_bit_num = 1;     // 1 stop bit
        parity_en = 0;        // parity off
        parity_type = 0;      // irrelevant khi parity_en=0
        cts_n = 0;            // cho phép truyền

        // Reset
        #100;
        rst_n = 1;

        // Chờ ổn định
        #100;

        // Gửi byte đầu tiên
        tx_data = 8'hA5;
        start_tx = 1;
        #20;
        start_tx = 0;

        // Đợi kết thúc truyền
        wait (tx_done == 1);

        #200;

        // Gửi byte thứ hai
        tx_data = 8'h5A;
        start_tx = 1;
        #20;
        start_tx = 0;

        wait (tx_done == 1);

        #200;

        $finish;
    end

    // Monitor tín hiệu chính
    initial begin
        $monitor("Time=%0t rst_n=%b start_tx=%b tx_done=%b tx=%b rts_n=%b", 
                 $time, rst_n, start_tx, tx_done, tx, rts_n);
    end

endmodule
