module APB_slave(
    input pclk,
    input prst_n,
    
    input  [11:0] paddr,
    input psel,
    input penable,
    input pwrite,
    input [31:0] pwdata,
    input [3:0] pstrb,

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

logic [31:0] wdata_tmp;

assign wdata_tmp[7:0] = pstrb[0] ? pwdata[7:0] : '0;
assign wdata_tmp[15:8] = pstrb[1] ? pwdata[15:8] : '0;
assign wdata_tmp[23:16] = pstrb[2] ? pwdata[23:16] : '0;
assign wdata_tmp[31:24] = pstrb[3] ? pwdata[31:24] : '0;

assign wdata_next = wr_en ? 0 : wdata;
assign pwdata_next = (psel & pwrite & penable) ? wdata_tmp : wdata_next;
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


//rd_en
assign rd_en = (psel & ~pwrite & penable);
//pready
assign pready = wack | rack;
//pslverr
assign pslverr = waddrerr | raddrerr;
//raddr
assign raddr = rd_en ? paddr : 0;
//prdata
assign prdata = rack ? rdata : 0;

endmodule