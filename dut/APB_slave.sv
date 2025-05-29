module APB_slave(
    input pclk,
    input prst_n,
    
    input  [11:0] paddr,
    input psel,
    input penable,
    input pwrite,
    input [31:0] pwdata,

    input  [31:0] rdata,
    input rack,
    input wack,
    input waddrerr,
    input raddrerr,

    output pready,
    output logic [31:0] prdata,
    output pslverr,

    output logic [11:0] waddr,
    output logic [11:0] raddr,
    output logic [31:0] wdata,
    output logic wr_en,
    output logic rd_en
);
// logic rd_en;
//wdata
logic [31:0] wdata_next;
logic [31:0] pwdata_next;
assign wdata_next = wr_en ? 0 : wdata;
assign pwdata_next = (psel & pwrite & penable) ? pwdata : wdata_next;
always_ff @( posedge pclk, negedge prst_n ) begin 
    if(~prst_n) begin
        wdata <= 0;
    end
    else begin
        wdata <= pwdata_next;
    end
end
// waddr
logic [11:0] waddr_next;
logic [11:0] paddr_next;
assign waddr_next = wr_en ? 0 : waddr;
assign paddr_next = (psel & pwrite & penable) ? paddr : waddr_next;
always_ff @( posedge pclk, negedge prst_n ) begin 
    if(~prst_n) begin
        waddr <= 0;
    end
    else begin
        waddr <= paddr_next;
    end
end

//raddr
logic [11:0] raddr_next;
logic [11:0] praddr_next;

assign raddr_next = rd_en ? 0 : raddr;
assign praddr_next = (rd_en) ? paddr : raddr_next;
always_ff @( posedge pclk, negedge prst_n ) begin 
    if(~prst_n) begin
        raddr <= 0;
    end
    else begin
        raddr <= praddr_next;
    end
end


//wr_en
logic wr_en_next;
logic wr_en_2;
assign wr_en_next = wr_en ? 0 : wr_en;
assign wr_en_2 = (psel & pwrite & penable) ? 1 : wr_en_next;
always_ff @( posedge pclk, negedge prst_n ) begin 
    if(~prst_n) begin
        wr_en <= 0;
    end
    else begin
        wr_en <= wr_en_2;
    end
end
// prdata

//rd_en
assign rd_en = (psel & ~pwrite & penable);
assign pready = wack | rack;
assign pslverr = waddrerr | raddrerr;

//prdata
assign prdata = pready ? rdata : 0;

endmodule