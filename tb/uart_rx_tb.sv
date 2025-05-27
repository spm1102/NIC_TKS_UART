`timescale 1ns/1ps

module uart_rx_tb();

    reg clk;
    reg rst_n;
    reg tick;
    reg rx;

    reg [1:0] data_bit_num;
    reg stop_bit_num;
    reg parity_en;
    reg parity_type;
    reg rts_n;

    wire rx_done;
    wire cts_n;
    wire parity_error;
    wire [7:0] rx_data;

    // Instance uart_rx
    uart_rx uut (
        .clk(clk),
        .tick(tick),
        .rst_n(rst_n),
        .rx(rx),
        .data_bit_num(data_bit_num),
        .stop_bit_num(stop_bit_num),
        .parity_en(parity_en),
        .parity_type(parity_type),
        .rts_n(rts_n),
        .rx_done(rx_done),
        .cts_n(cts_n),
        .parity_error(parity_error),
        .rx_data(rx_data)
    );

    // Clock generation 50 MHz
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Generate tick at baud rate ~9600 (every 326 clocks)
    integer tick_counter = 0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick <= 0;
            tick_counter <= 0;
        end else begin
            if (tick_counter == 163) begin
                tick <= 1;
                tick_counter <= 0;
            end else begin
                tick <= 0;
                tick_counter <= tick_counter + 1;
            end
        end
    end

    // Task giữ tín hiệu rx trong 16 tick
    task uart_send_bit(input bit_val);
        integer j;
        begin
            rx = bit_val;
            for (j = 0; j < 16; j = j + 1) begin
                @(posedge tick);
            end
        end
    endtask

    // Task gửi 1 byte UART, hỗ trợ parity và stop bit
    task uart_send_byte(input [7:0] data);
        integer i;
        reg parity_bit;
        begin
            // Start bit = 0
            uart_send_bit(0);

            // Data bits theo data_bit_num
            parity_bit = 0;
            for (i = 0; i < (data_bit_num + 5); i = i + 1) begin
                uart_send_bit(data[i]);
                parity_bit = parity_bit ^ data[i];
            end

            // Parity bit (nếu enable)
            if (parity_en) begin
                if (parity_type) // odd parity
                    uart_send_bit(~parity_bit);
                else            // even parity
                    uart_send_bit(parity_bit);
            end

            // Stop bit(s)
            uart_send_bit(1);
            if (stop_bit_num)
                uart_send_bit(1);
        end
    endtask

    // Procedure test 1 case
    task test_case(
        input [7:0] test_data,
        input [1:0] test_data_bit_num,
        input test_stop_bit_num,
        input test_parity_en,
        input test_parity_type
    );
    begin
        data_bit_num = test_data_bit_num;
        stop_bit_num = test_stop_bit_num;
        parity_en = test_parity_en;
        parity_type = test_parity_type;

        $display("\n--- Test case: data_bits=%0d, stop_bit=%0d, parity_en=%0b, parity_type=%0b ---",
                 data_bit_num+5, stop_bit_num ? 2 : 1, parity_en, parity_type);

        uart_send_byte(test_data);

        wait(rx_done);

        #20; // chờ tín hiệu ổn định

        $display("Sent byte: %h, Received byte: %h, Parity error: %b", test_data, rx_data, parity_error);

        #100;
    end
    endtask

    initial begin
        // Initialize
        rst_n = 0;
        rx = 1; // idle line
        rts_n = 1;

        #100;
        rst_n = 1;

        #100;

        // Test 1: 8 data bits, 1 stop bit, no parity
        test_case(8'hA5, 2'b11, 0, 0, 0);

        // Test 2: 7 data bits, 1 stop bit, parity even
        test_case(8'h55, 2'b10, 0, 1, 0);

        // Test 3: 6 data bits, 2 stop bits, parity odd
        test_case(8'h2A, 2'b01, 1, 1, 1);

        // Test 4: 5 data bits, 2 stop bits, no parity
        test_case(8'h1B, 2'b00, 1, 0, 0);

        #500;
        #15000
        $finish;
    end

endmodule
