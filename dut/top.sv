module top#(parameter baurate = 9600)(
    input               clk,
    // input               tick,
    input               rst_n,
    input [10:0]        dvsr,
    input [7:0]         tx_data,

    input               start_tx,
    input [1:0]         data_bit_num,
    input               stop_bit_num,
    input               parity_en,
    input               parity_type,

    input               cts_n,

    output logic        tx,
    output logic        tx_done,
    output logic        rts_n
);
logic tick;
uart_tx uart_tx_inst (
    .clk(clk),
    .tick(tick),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .start_tx(start_tx),
    .data_bit_num(data_bit_num),
    .stop_bit_num (stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .cts_n(cts_n),
    .tx(tx),
    .tx_done(tx_done),
    .rts_n(rts_n)
);
baud_generator baud_generator_inst(
    .clk(clk),
    .rst_n(rst_n),
    .dvsr(dvsr),
    .tick(tick)
);



endmodule