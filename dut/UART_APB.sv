module UART_APB#(parameter baurate = 9600,
                            clk_hz = 100000000)(
    input clk, 
    input rst_n,

    input pclk,
    input presetn,

    input psel,
    input penable,
    input pwrite,
    input [3:0] pstrb,
    input [11:0] paddr,
    input [31:0] pwdata,

    output pready,
    output pslverr,
    output [31:0] prdata,

    input rx,
    input cts_n,
    output tx,
    output rts_n
);
localparam dvsr = clk_hz / ((baurate + 1) * 16);

logic [31:0] rdata;

logic rack ;
logic wack;

logic waddrerr;
logic raddrerr;

logic [11:0] waddr;
logic [11:0] raddr;

logic wr_en;
logic rd_en;

logic [31:0] wdata;

logic tick;

logic [7:0] tx_data;
logic [1:0] data_bit_num;
logic stop_bit_num;
logic parity_en;
logic parity_type;
logic start_tx;
logic tx_done;
logic start_tx_down;

logic [7:0] rx_data;
logic rx_done;
logic parity_error;


APB_slave APB_slave_inst (
    .pclk(pclk),
    .prst_n(prst_n),
    .paddr(paddr),
    .psel (psel),
    .penable(penable),
    .pwrite(pwrite),
    .pstrb(pstrb),
    .pwdata(pwdata),
    .rdata(rdata),
    .rack(rack),
    .wack(wack),
    .waddrerr(waddrerr),
    .raddrerr(raddrerr),
    .pready(pready),
    .prdata(prdata),
    .pslverr(pslverr),
    .waddr(waddr),
    .raddr(raddr),
    .wdata(wdata),
    .wr_en(wr_en),
    .rd_en(rd_en)
);
Registor_block Resgistor_block_inst(
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
    .start_tx_down(start_tx_down),
    .rdata(rdata),
    .rack(rack),
    .wack(wack),
    .waddrerr(waddrerr),
    .raddrerr(raddrerr)
);
baud_generator baud_generator_inst(
    .clk(clk),
    .rst_n(rst_n),
    .dvsr(dvsr),
    .tick(tick)
);
uart_tx uart_tx_inst(
    .clk(clk),
    .rst_n(rst_n),
    .tick(tick),
    .tx_data(tx_data),
    .start_tx(start_tx),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .cts_n(cts_n),
    .tx(tx),
    .tx_done(tx_done),
    .start_tx_down(start_tx_down)
);
uart_rx uart_rx_inst(
    .clk(clk),
    .rst_n(rst_n),
    .tick(tick),
    .rx(rx),
    .data_bit_num(data_bit_num),
    .stop_bit_num(stop_bit_num),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .rd_en(rd_en),
    .raddr(raddr),
    // .cts_n(),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .rts_n(rts_n),
    .parity_error(parity_error)
);


endmodule