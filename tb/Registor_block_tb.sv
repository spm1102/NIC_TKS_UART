`timescale 1ns/1ps

module Resgistor_block_tb;

    // Clock and reset
    logic clk;
    logic rst_n;

    // Inputs
    logic [11:0] waddr;
    logic [11:0] raddr;
    logic [31:0] wdata;
    logic wr_en;
    logic rd_en;

    logic [31:0] rx_data;
    logic tx_done;
    logic rx_done;
    logic parity_error;

    // Outputs
    logic [7:0] tx_data;
    logic [1:0] data_bit_num;
    logic stop_bit_num;
    logic parity_en;
    logic parity_type;
    logic start_tx;

    logic [31:0] rdata;
    logic rack;
    logic wack;
    logic waddrerr;
    logic raddrerr;

    // Instantiate the DUT (Design Under Test)
    Resgistor_block dut (
        .clk(clk),
        .rst_n(rst_n),
        .waddr(waddr),
        .raddr(raddr),
        .wdata(wdata),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .rx_data(rx_data),
        .tx_done(tx_done),
        .rx_done(rx_done),
        .parity_error(parity_error),
        .tx_data(tx_data),
        .data_bit_num(data_bit_num),
        .stop_bit_num(stop_bit_num),
        .parity_en(parity_en),
        .parity_type(parity_type),
        .start_tx(start_tx),
        .rdata(rdata),
        .rack(rack),
        .wack(wack),
        .waddrerr(waddrerr),
        .raddrerr(raddrerr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Stimulus
    initial begin
        // Initialize inputs
        waddr = 0;
        raddr = 0;
        wdata = 0;
        wr_en = 0;
        rd_en = 0;
        rx_data = 8'hAA;    // Giả sử nhận được dữ liệu 0xAA từ UART
        tx_done = 1'b0;
        rx_done = 1'b0;
        parity_error = 1'b0;

        @(posedge rst_n);
        @(posedge clk);

        // Test 1: Write tx_data
        waddr = 12'b0;
        wdata = 32'h55; // Data = 0x55
        wr_en = 1;
        @(posedge clk);
        wr_en = 0;
        @(posedge clk);

        // Test 2: Write config register
        waddr = 12'b1000;
        wdata = {27'b0, 5'b10101}; // data_bit_num=01, stop_bit_num=1, parity_en=0, parity_type=1
        wr_en = 1;
        @(posedge clk);
        wr_en = 0;
        @(posedge clk);

        // Test 3: Write control register (start transmission)
        waddr = 12'b1100;
        wdata = 32'h1; // start_tx = 1
        wr_en = 1;
        @(posedge clk);
        wr_en = 0;
        @(posedge clk);

        // Test 4: Read tx_data
        raddr = 12'b0;
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        $display("Read TX_DATA = 0x%0h", rdata);

        // Test 5: Read config
        raddr = 12'b1000;
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        $display("Read CFG = 0x%0h", rdata);

        // Test 6: Read control
        raddr = 12'b1100;
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        $display("Read CTRL = 0x%0h", rdata);

        // Test 7: Read rx_data
        raddr = 12'b100;
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        $display("Read RX_DATA = 0x%0h", rdata);

        // Test 8: Read status
        tx_done = 1;
        rx_done = 1;
        parity_error = 1;
        raddr = 12'b10000;
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        $display("Read STT = 0x%0h", rdata);

        // Finish simulation
        #50;
        $finish;
    end

endmodule
