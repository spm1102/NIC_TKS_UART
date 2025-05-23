module top (

    // Clock and reset
    logic        pclk,
    logic        prst_n,

    // APB interface signals
    logic        psel,
    logic        penable,
    logic        pwrite,
    logic [3:0]  pstrb,
    logic [11:0] paddr,
    logic [31:0] pwdata,

    logic        pready,
    logic        pslverr,
    logic [31:0] prdata,
    logic [4:0]  enable,
    logic [31:0] data_out
);
    // Instantiate the APB slave
    logic rack, wack, waddrerr, raddrerr;
    logic [11:0] waddr, raddr;
    logic [31:0] wdata;
    logic wr_en, rd_en;

    APB_slave apb_slave_inst (
        .pclk     (pclk),
        .prst_n   (prst_n),
        .psel     (psel),
        .penable  (penable),
        .pwrite   (pwrite),
        .paddr    (paddr),
        .pwdata   (pwdata),

        .rdata    (32'd0),        
        .rack     (rack),
        .wack     (wack),
        .waddrerr (1'b0),         
        .raddrerr (1'b0),

        .pready   (pready),
        .prdata   (prdata),
        .pslverr  (pslverr),
        .waddr    (waddr),
        .raddr    (raddr),
        .wdata    (wdata),
        .wr_en    (wr_en),
        .rd_en    (rd_en)
    );
endmodule
