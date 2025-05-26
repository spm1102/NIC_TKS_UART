`timescale 1ns/1ps

module baud_generator_tb();

    reg clk;
    reg rst_n;
    reg [10:0] dvsr;
    wire tick;

    // Instance baud_generator
    baud_generator uut (
        .clk(clk),
        .rst_n(rst_n),
        .dvsr(dvsr),
        .tick(tick)
    );

    // Clock generation: 50 MHz => 20 ns period
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // toggle every 10 ns
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        rst_n = 0;
        dvsr = 11'd5207; // Example for 50 MHz clock -> 9600 baud

        // Reset pulse
        #50;
        rst_n = 1;

        // Run simulation for some time to observe ticks
        #105000;  // khoảng 2 ms simulation

        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t clk=%b rst_n=%b dvsr=%d r_reg=? tick=%b", $time, clk, rst_n, dvsr, tick);
    end

endmodule
