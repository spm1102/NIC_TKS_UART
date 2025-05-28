`timescale 1ns/1ps

module uart_rx_tb;

    logic clk;
    logic rst_n;
    logic tick;
    logic rx;
    logic [1:0] data_bit_num;
    logic stop_bit_num;
    logic parity_en;
    logic parity_type;
    logic rts_n;

    logic rx_done;
    logic parity_error;
    logic [7:0] rx_data;

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
        .parity_error(parity_error),
        .rx_data(rx_data)
    );

    // Clock generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Tick generation (every 1040ns for 9600 baud with 16x oversampling)
    initial tick = 0;
    always begin
        #1040 tick = 1;
        #10 tick = 0;
    end

    // Task to send a UART frame
    // UART frame sender task with proper parity calculation
    task send_uart_frame(
      input [7:0] data,
      input [1:0] num_data_bits,
      input num_stop_bits,
      input parity_enable,
      input parity_odd
    );
      integer i, actual_data_bits;
      logic calc_parity;
      begin
        // Calculate actual number of data bits (5,6,7,8)
        actual_data_bits = num_data_bits + 5;
        
        $display("Sending frame: data=0x%02h, data_bits=%0d, stop_bits=%0d, parity_en=%0b, parity_type=%s",
                data, actual_data_bits, num_stop_bits ? 2 : 1, parity_enable, parity_odd ? "odd" : "even");

        // Start bit
        rx <= 0;
        repeat (16) @(posedge tick);

        // Data bits (LSB first) - only send the required number of bits
        calc_parity = 0;
        for (i = 0; i < actual_data_bits; i++) begin
          rx <= data[i];
          calc_parity = calc_parity ^ data[i]; // Calculate parity
          repeat (16) @(posedge tick);
        end

        // Parity bit (if enabled)
        if (parity_enable) begin
          if (parity_odd)
            rx <= ~calc_parity; // Odd parity
          else
            rx <= calc_parity;   // Even parity
          repeat (16) @(posedge tick);
        end
        wait(rx_done == 1);

        // Stop bits
        rx <= 1;
        repeat (16) @(posedge tick);
        
        if (num_stop_bits) begin // 2 stop bits
          rx <= 1;
          repeat (16) @(posedge tick);
        end

        // Idle time between frames
        repeat (16) @(posedge tick);
      end
    endtask
    // Test case task
    task test_case(
      input [7:0] test_data,
      input [1:0] test_data_bits,
      input test_stop_bits,
      input test_parity_en,
      input test_parity_type,
      input string test_name
    );
    begin
      $display("\n=== %s ===", test_name);
      
      // Configure UART settings
      data_bit_num <= test_data_bits;
      stop_bit_num <= test_stop_bits;
      parity_en <= test_parity_en;
      parity_type <= test_parity_type;
      
      // Wait for settings to propagate
      repeat (10) @(posedge clk);
      
      // Send UART frame
      send_uart_frame(test_data, test_data_bits, test_stop_bits, test_parity_en, test_parity_type);

      // Wait for reception to complete
      //wait (rx_done == 1);
      repeat (5) @(posedge clk);

      // Display results
      $display("Expected: 0x%02h, Received: 0x%02h, Parity Error: %b, Match: %s", 
              test_data, rx_data, parity_error, 
              (rx_data == test_data && !parity_error) ? "PASS" : "FAIL");
      
      // Wait for rx_done to deassert
      wait (rx_done == 0);
      repeat (32) @(posedge tick);
    end
    endtask
    initial begin
    // Initialize signals
        rx <= 1; // UART line idle high
        rst_n <= 0;
        rts_n <= 0; // Ready to receive
        
        // Initialize configuration to safe defaults
        data_bit_num <= 2'b11; // 8 bits
        stop_bit_num <= 1'b0;  // 1 stop bit
        parity_en <= 0;        // No parity
        parity_type <= 0;      // Even parity (when enabled)

        // Reset pulse
        #200;
        rst_n <= 1;
        #200;

        $display("Starting UART RX Tests...");
        $display("Received: %h, Parity Error: %b", rx_data, parity_error);
         // Test 1: Basic 8N1 (8 data bits, no parity, 1 stop bit)
        test_case(8'hA5, 2'b11, 1'b0, 1'b0, 1'b0, "Test 1: 8N1 - 0xA5");

        // Test 2: 7E1 (7 data bits, even parity, 1 stop bit)
        test_case(8'h55, 2'b10, 1'b0, 1'b1, 1'b0, "Test 2: 7E1 - 0x55");

        // Test 3: 6O2 (6 data bits, odd parity, 2 stop bits)
        test_case(8'h2A, 2'b01, 1'b1, 1'b1, 1'b1, "Test 3: 6O2 - 0x2A");

        // Test 4: 5N2 (5 data bits, no parity, 2 stop bits)
        test_case(8'h1B, 2'b00, 1'b1, 1'b0, 1'b0, "Test 4: 5N2 - 0x1B");

        // Test 5: 8E1 with different data patterns
        test_case(8'h00, 2'b11, 1'b0, 1'b1, 1'b0, "Test 5: 8E1 - 0x00");
        test_case(8'hFF, 2'b11, 1'b0, 1'b1, 1'b0, "Test 6: 8E1 - 0xFF");

        #5000;
        $finish;
    end

endmodule
