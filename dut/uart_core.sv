module uart #(parameter baurate = 9600,
                        clk_hz = 50000000)(
    input               clk,
    input               reset_n,

    input [7:0]         tx_data,
    input               rx,
    input               start_tx,
    input [1:0]         data_bit_num,
    input               stop_bit_num,
    input               parity_en,
    input               parity_type,

    input               cts_n,

    output              rts_n,
    output [7:0]        rx_data,
    output logic        tx,
    output logic        tx_done,
    output logic        rx_done,
    output logic        parity_error

    // output logic        rts_n

);
logic tick;
localparam dvsr = clk_hz / ((baurate + 1) * 16);
uart_tx uart_tx_inst(
    .clk(clk),
    .rst_n(reset_n),
    .tick(tick),
    .tx_data(tx_data),
    .start_tx(start_tx),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .cts_n(cts_n),
    .tx(tx),
    .tx_done(tx_done)
    // .start_tx_down(start_tx_down)
);
baud_generator baud_generator_inst(
    .clk(clk),
    .rst_n(reset_n),
    .dvsr(dvsr),
    .tick(tick)
);
uart_rx uart_rx_inst(
    .clk(clk),
    .rst_n(reset_n),
    .tick(tick),
    .rx(rx),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    // .rd_en(rd_en),
    // .raddr(raddr),
    // .cts_n(),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .rts_n(rts_n),
    .parity_error(parity_error)
);
endmodule