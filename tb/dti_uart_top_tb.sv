//-----------------------------------------------------------------------------
//    Copyright (C) 2016 by Dolphin Technology
//    All right reserved.
//    
//    Copyright Notification
//    No part may be reproduced except as authorized by written permission.
//    
//    File: ../sim/tb/dti_uart_top_tb.sv
//    Project: dti_uart
//    Author: hungnm0
//    Created: October 24rd 2024
//    Description:
//       APB Bridge
//    
//    History:
//    Date ------------ By ------------ Change Description
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module dti_uart_top_tb;

parameter CFG_REG_5_BIT = 0;
parameter CFG_REG_6_BIT = 1;
parameter CFG_REG_7_BIT = 2;
parameter CFG_REG_8_BIT = 3;

parameter STOP_BIT_1 = 0;
parameter STOP_BIT_2 = 1;
parameter PARITY_NOT = 0;
parameter PARITY_EN = 1;
parameter PARITY_EVEN = 1;
parameter PARITY_ODD = 0;
// Parameters
parameter DATA_WIDTH = 32;
parameter TRANS_DATA_WIDTH = 8;
parameter DATA_BIT_NUM_WIDTH = 2;

// Testbench signals
reg clk;
reg reset_n;
reg pclk;
reg presetn;
reg rx_c;
reg [11:0] paddr;
reg psel;
reg pwrite;
reg penable;
wire pslverr;
reg [3:0] pstrb;
reg [DATA_WIDTH - 1 : 0] pwdata;
wire [DATA_WIDTH - 1 : 0] prdata;
wire tx_c;
wire rts_n_c;
reg cts_n_c;

// Instantiate the uart_top module

//     .DATA_WIDTH(DATA_WIDTH),
//     .TRANS_DATA_WIDTH(TRANS_DATA_WIDTH),
//     .DATA_BIT_NUM_WIDTH(DATA_BIT_NUM_WIDTH)
// )
UART_APB uut (
    .clk(clk),
    .rst_n(reset_n),
    .pclk(pclk),
    .presetn(presetn),
    .rx(rx_c),
    .paddr(paddr),
    .psel(psel),
    .pwrite(pwrite),
    .penable(penable),
    .pslverr(pslverr),
    .pstrb(pstrb),
    .pwdata(pwdata),
    .prdata(prdata),
    .tx(tx_c),
    .rts_n(rts_n_c),
    .cts_n(cts_n_c)
);

// Clock generation
always #5 clk = ~clk;
always #5 pclk = ~pclk; 
//task to initialize the system
task system_reset();
begin
    reset_n = 1'b0;
    presetn = 1'b0;
    @(posedge clk);
    reset_n = 1'b1;
    presetn = 1'b1;
    @(posedge clk);
end
endtask
task setup_reg_mode(input[1:0] data_bit,input stop_bit,input parity_en_t,input parity_type_t);
begin
    paddr = 12'h008;
    pwdata = data_bit + stop_bit*4 + parity_en_t*8 + parity_type_t*16;
    pwrite = 1;
    psel = 1;
    pstrb = 4'b1111;
    @(posedge clk);
    penable = 1;
    @(posedge clk);
    pwrite = 0;
    penable = 0;
end
endtask

task read_reg(input [11:0] addr); begin
    paddr = addr;
    pwdata = 0;
    penable = 1;
    @(posedge clk);
    penable = 0;
end
endtask

task check_rx(); begin
    paddr = 12'h10;
    pwdata = 0;
    penable = 1;
    @(posedge clk);
    while(prdata [1] != 1 ) begin
        @(posedge clk);
    end
    $display("checked_rx");
    pwdata = 0;
    paddr = 12'h4;
    @(posedge clk);
    $display("%h",prdata);
end
endtask

task check_rx_1(); begin
    @(posedge clk);
    paddr = 12'h10;
    pwdata = 0;
    penable = 1;
     @(posedge clk);
    while(prdata [1] != 1 ) begin
        @(posedge clk);
    end
    $display("checked_rx");
    pwdata = 0;
    paddr = 12'h04;
    @(posedge clk);
    @(posedge clk);
    //@(negedge uut.uart_rx_inst.rx_done);
    $display("%h",prdata);
end
endtask
//task to hold data of bit
task hold_data(input integer time_hold); begin
    repeat(time_hold) begin
    @(posedge clk);
    end
end
endtask


// Task to simulate receiving data
task receive_data(input [TRANS_DATA_WIDTH-1:0] data,input [3:0] length_bit);
begin
    rx_c = 1'b0;  // Start bit
    hold_data(10416);
    // Send data bits (LSB first)
    for (integer i = 0; i < length_bit; i = i + 1) begin
        rx_c = data[i];
        hold_data(10416);
    end

    rx_c = 1'b1;  // Stop bit
    hold_data(10416);  // Wait for stop bit time
end
endtask

task receive_data_with_parity(input [TRANS_DATA_WIDTH-1:0] data, input [3:0] length_bit,input error,input stop_bit);
begin
    rx_c = 1'b0;  // Start bit
    hold_data(10416);
    // Send data bits (LSB first)
    for (integer i = 0; i < length_bit; i = i + 1) begin
        rx_c = data[i];
        hold_data(10416);
    end
    rx_c = error; //parity bit
    hold_data(10416);
    rx_c = 1'b1;  // Stop bit
    hold_data(10416);  // Wait for stop bit time
    if(stop_bit == 1) begin
    rx_c = 1'b1;  // Stop bit
    hold_data(10416); 
    end
end
endtask

//first test of tx mode
task setup_tx_mode(input [TRANS_DATA_WIDTH-1:0] data);begin
    paddr = 12'h0; //tx_data
    pwrite = 1;
    //data_tx
    pwdata = data ;
    psel = 1;
    pstrb = 4'b1111;
    @(posedge clk);
    penable = 1;
    @(posedge clk);
    penable = 0;
    paddr = 12'hC;
    //start_tx
    pwdata = 32'h1; //ctrl_reg
    @(posedge clk);
    penable = 1;
    @(posedge clk);
    penable = 0;
end
endtask
task check_tx_done();begin
    @(posedge clk);
    paddr = 12'h10;
    pwrite = 0;
    penable = 1;
    repeat(100) @(posedge clk);
    // while(prdata[0] == 0) @(posedge clk);
    @(posedge uut.uart_tx_inst.tx_done);
    $display("finish_tx");
end
endtask
task uart_rx_virt_task(output reg [7:0] data_out);
    integer i;
    integer baud_clk_cycles;
    reg [7:0] data_reg;
begin
    baud_clk_cycles = 10416;  // Chu kỳ 1 bit theo clock 100MHz và baudrate 9600
    
    // Đợi start bit (tx line kéo xuống 0)
    wait(tx_c == 0);
    
    // Đợi chính giữa start bit
    repeat(baud_clk_cycles / 2) @(posedge clk);
    
    // Đọc 8 bit dữ liệu (LSB first)
    for (i = 0; i < 8; i = i + 1) begin
        repeat(baud_clk_cycles) @(posedge clk);
        data_reg[i] = tx_c;
    end
    
    // Đọc stop bit (bỏ qua)
    repeat(baud_clk_cycles) @(posedge clk);
    
    data_out = data_reg;
    $display("RX_virt received data: %02X at time %t", data_out, $time);
end
endtask

// --- Task để test truyền data và đợi RX ảo nhận ---
task test_tx_data(input [7:0] tx_data);
    reg [7:0] rx_data;
begin
    $display("Sending TX data: %02X at time %t", tx_data, $time);
    setup_tx_mode(tx_data);
    uart_rx_virt_task(rx_data);
    if (rx_data !== tx_data) begin
        $display("ERROR: RX data %02X does not match TX data %02X", rx_data, tx_data);
    end else begin
        $display("SUCCESS: RX data matches TX data");
    end
end
endtask
// test rx
initial begin
    //////////////////////////////////////test rx ///////////////////////////
    // Wait a bit after reset
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    //receive_data(8'h49,8);

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);


    //receive_data(8'hFF,5);


    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);

    receive_data_with_parity(8'hB6,8,1,0); //tested
    // check_rx_1();
    // receive_data_with_parity(8'hB6,8,0,1); //tested
    // // receive_data_with_parity(8'hDA,8,0,1); //tested
    receive_data_with_parity(8'hC2,8,0,1); //tested
    // receive_data_with_parity(8'h51,8,0,1); //tested
    // receive_data_with_parity(8'h97,8,0,1); //tested
    // receive_data_with_parity(8'h22,8,0,1); //tested
    // receive_data_with_parity(8'h53,8,0,1); //tested
    // receive_data_with_parity(8'hBA,8,0,1); //tested
    // receive_data_with_parity(8'hA4,8,0,1); //tested
    // receive_data_with_parity(8'h4B,8,0,1); //tested
    // Add more stimuli as needed for the rx functionality
    // For example, you can check if the received data is stored correctly

end
//initial for reg
initial begin
     // Initialize signals
    clk = 0;
    pclk = 0;
    reset_n = 1;
    presetn = 1;
    psel = 0;
    pwrite = 0;
    penable = 0;
    rx_c = 1;
    pstrb = 4'b0000;
    pwdata = 0;
    paddr = 12'b0;
    cts_n_c = 0;
    // Reset the system
    system_reset;


    // DATA_BIT 8 NO PARITY AND 1 STOP BIT
    //setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_1,PARITY_NOT,PARITY_EVEN);


    // DATA_BIT 5 NO PARITY AND 1 STOP BIT
    //setup_reg_mode(CFG_REG_6_BIT,STOP_BIT_2,PARITY_EN,PARITY_EVEN); //checked tx
    //setup_reg_mode(CFG_REG_7_BIT,STOP_BIT_2,PARITY_EN,PARITY_EVEN); //checked tx
    //setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_2,PARITY_EN,PARITY_ODD); //checked tx
    //setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_2,PARITY_EN,PARITY_EVEN); //checked tx
    //setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_2,PARITY_EN,PARITY_ODD); //checked tx
    //check_rx;
    //repeat(10) @(posedge clk);
    // setup_reg_mode(CFG_REG_5_BIT,STOP_BIT_2,PARITY_NOT,PARITY_EVEN);
    // repeat(10) @(posedge clk);

    // DATA_BIT 5 EVEN PARITY AND 1 STOP BIT
    setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_1,PARITY_EN,PARITY_EVEN);
    test_tx_data(8'hA5);
    repeat(10000) @(posedge clk);
    test_tx_data(8'h37);
    repeat(10000) @(posedge clk); 
    test_tx_data(8'hB8);
    repeat(10000) @(posedge clk);
    test_tx_data(8'hB9);
    repeat(10000) @(posedge clk);
    setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_1,PARITY_EN,PARITY_ODD);
    test_tx_data(8'hB1);
    repeat(10000) @(posedge clk);
    test_tx_data(8'hD3);
    repeat(10000) @(posedge clk); 
    test_tx_data(8'hC2);
    repeat(10000) @(posedge clk);
    test_tx_data(8'h55);
    repeat(10000) @(posedge clk);
    setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_1,PARITY_NOT,PARITY_ODD);
    test_tx_data(8'hB1);
    repeat(20000) @(posedge clk);
    test_tx_data(8'hD3);
    repeat(10000) @(posedge clk); 
    test_tx_data(8'hC2);
    repeat(10000) @(posedge clk);
    test_tx_data(8'h55);
    repeat(10000) @(posedge clk);
    // check_rx_1();
    // check_rx_1();
    //check_rx;
    /////////////////////////////////////////test mode rx/////////////////////////////////
    //check_rx();
    // check_rx();
    // check_rx();
    // check_rx();
    // check_rx();setup_tx_mode
    // check_rx();
    // check_rx();
    // check_rx();
    // check_rx();
    // check_rx();
    /////////////////////////////////////////test mode tx/////////////////////////////////
    // //test_1
    // //setup_tx_mode(8'h82);
    // setup_tx_mode(8'hA5);
    // check_tx_done;
    // setup_tx_mode(8'h37);
    // check_tx_done;
    // setup_tx_mode(8'hb7);
    // check_tx_done;
    // repeat(10000)begin
    //     @(posedge clk);
    // end
    // setup_reg_mode(CFG_REG_8_BIT,STOP_BIT_2,PARITY_EN,PARITY_ODD);
    // setup_tx_mode(8'hA5);
    // check_tx_done;
    // setup_tx_mode(8'h37);
    // check_tx_done;
    // setup_tx_mode(8'hb7);
    // check_tx_done;
    // repeat(10000)begin
    //     @(posedge clk);
    // end
    // setup_reg_mode(CFG_REG_7_BIT,STOP_BIT_1,PARITY_NOT,PARITY_ODD);
    // setup_tx_mode(7'b1100101);
    // check_tx_done;
    // setup_tx_mode(7'b1010011);
    // check_tx_done;
    // setup_tx_mode(7'b1111000);
    // check_tx_done;
    // repeat(10000)begin
    //     @(posedge clk);
    // end
    // setup_reg_mode(CFG_REG_7_BIT,STOP_BIT_2,PARITY_EN,PARITY_EVEN);
    // setup_tx_mode(7'b1100101);
    // check_tx_done;
    // setup_tx_mode(7'b1010011);
    // check_tx_done;
    // setup_tx_mode(7'b1111000);
    // check_tx_done;
    // repeat(10000)begin
    //     @(posedge clk);
    // end
    // setup_reg_mode(CFG_REG_6_BIT,STOP_BIT_1,PARITY_EN,PARITY_EVEN);
    // setup_tx_mode(6'b101001);
    // check_tx_done;
    // setup_tx_mode(6'b111000);
    // check_tx_done;
    // setup_tx_mode(6'b110011);
    // check_tx_done;
    // repeat(10000)begin
    //     @(posedge clk);
    // end

    //////test_tx////////////////////
    $finish;
end
endmodule
