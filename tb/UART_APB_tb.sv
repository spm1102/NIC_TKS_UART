`timescale 1ns/1ps

module uart_apb_tb;

    // APB signals
    reg clk;
    reg rst_n;
    reg pclk;
    reg presetn;
    reg psel;
    reg penable;
    reg pwrite;
    reg [3:0] pstrb;
    reg [11:0] paddr;
    reg [31:0] pwdata;
    wire pready;
    wire pslverr;
    wire [31:0] prdata;

    // UART signals
    reg rx;
    reg cts_n;
    wire tx;
    wire rts_n;

    // Declare missing variables
    reg [7:0] tx_data;  // Data to be transmitted
    reg start_tx;       // Signal to start transmission
    reg [1:0] data_bit_num;  // Data bit number (e.g., 8-bit)
    reg stop_bit_num;   // Stop bit number (1 or 2)
    reg parity_en;      // Enable parity check
    reg parity_type;    // Parity type (even or odd)

    // Instantiate UART_APB module
    UART_APB uut (
        .clk(clk),
        .rst_n(rst_n),
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pstrb(pstrb),
        .paddr(paddr),
        .pwdata(pwdata),
        .pready(pready),
        .pslverr(pslverr),
        .prdata(prdata),
        .rx(rx),
        .cts_n(cts_n),
        .tx(tx),
        .rts_n(rts_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end

    // APB clock generation
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk; // 100 MHz clock
    end

    // Initialize and drive APB signals
    initial begin
        // Reset all signals
        rst_n = 0;
        psel = 0;
        penable = 0;
        pwrite = 0;
        pstrb = 4'b1111;
        paddr = 12'd0;
        pwdata = 32'd0;

        #100;
        rst_n = 1;  // Release reset
        #100;

        // Test writing to config register
        write_config_register(12'h001, 32'hABCD1234);  // Write to config register

        // Test writing to data register
        write_data_register(12'h002, 32'hA5A5A5A5);  // Write to data register

        // Test writing to control register
        write_control_register(12'h003, 32'h00000001);  // Start TX transmission

        // Test data transmission
        transmit_data(32'hDEADBEEF, 2'b11, 0, 0, 0);  // 8 data bits, no parity, 1 stop bit

        // Monitor TX output and check RX data
        #500;
        $display("TX data transmitted: %h", 32'hDEADBEEF);
        $display("RX data received: %h", uut.uart_rx_inst.rx_data);  // Fixed reference to rx_data
        $display("Parity error: %b", uut.uart_rx_inst.parity_error);  // Fixed reference to parity_error
        
        #500;
        $finish;
    end

    // Task: Write to config register
    task write_config_register(input [11:0] address, input [31:0] config_value);
        begin
            psel = 1;
            pwrite = 1;  // Write operation
            paddr = address;
            pwdata = config_value;
            penable = 1;
            #10;
            penable = 0;
            psel = 0;
        end
    endtask

    // Task: Write to data register
    task write_data_register(input [11:0] address, input [31:0] data_value);
        begin
            psel = 1;
            pwrite = 1;  // Write operation
            paddr = address;
            pwdata = data_value;
            penable = 1;
            #10;
            penable = 0;
            psel = 0;
        end
    endtask

    // Task: Write to control register
    task write_control_register(input [11:0] address, input [31:0] control_value);
        begin
            psel = 1;
            pwrite = 1;  // Write operation
            paddr = address;
            pwdata = control_value;
            penable = 1;
            #10;
            penable = 0;
            psel = 0;
        end
    endtask

    // Task: Transmit data
    task transmit_data(input [31:0] data_to_transmit, input [1:0] data_bit_num, input stop_bit_num, input parity_en, input parity_type);
        begin
            // Write data to data register
            write_data_register(12'h001, data_to_transmit);  // Write to data register

            // Write to control register to start TX transmission
            write_control_register(12'h003, 32'h1);  // Start TX transmission by writing 1 to control register

            // Send data over UART TX
            tx_data = data_to_transmit[7:0]; // Send 8 bits of data
            data_bit_num = data_bit_num;
            stop_bit_num = stop_bit_num;
            parity_en = parity_en;
            parity_type = parity_type;
            start_tx = 1;  // Activate start transmission
            #10; // Wait for the data to be sent
            start_tx = 0;
        end
    endtask

    // Task to send a bit (hold rx for 16 ticks)
    task uart_send_bit(input bit_val);
        integer j;
        begin
            rx = bit_val;
            for (j = 0; j < 16; j = j + 1) begin
                @(posedge clk);
            end
        end
    endtask

    // Task to send a byte (8 bits) through UART TX
    task uart_send_byte(input [7:0] data);
        integer i;
        reg parity_bit;
        begin
            // Start bit = 0
            uart_send_bit(0);

            // Data bits (LSB first)
            parity_bit = 0;
            for (i = 0; i < 8; i = i + 1) begin
                uart_send_bit(data[i]);
                parity_bit = parity_bit ^ data[i];
            end

            // Parity bit (if enabled)
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

    // Monitor signals during simulation
    initial begin
        $monitor("Time=%0t, rx_done=%b, rx_data=%h, parity_error=%b", $time, uut.uart_rx_inst.rx_done, uut.uart_rx_inst.rx_data, uut.uart_rx_inst.parity_error);
    end
endmodule
