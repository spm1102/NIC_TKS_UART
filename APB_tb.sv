`timescale 1ns/1ps

module APB_slave_tb();

  // Clock and reset
  logic pclk;
  logic prst_n;

  // APB interface signals
  logic [11:0] paddr;
  logic psel;
  logic penable;
  logic pwrite;
  logic [31:0] pwdata;
  logic [31:0] rdata;
  logic rack;
  logic wack;
  logic waddrerr;
  logic raddrerr;

  logic pready;
  logic [31:0] prdata;
  logic pslverr;
  logic [11:0] waddr;
  logic [11:0] raddr;
  logic [31:0] wdata;
  logic wr_en;

  // Instantiate DUT
  APB_slave dut(
    .pclk(pclk),
    .prst_n(prst_n),
    .paddr(paddr),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
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
    .wr_en(wr_en)
  );

  // Clock generation
  initial pclk = 0;
  always #5 pclk = ~pclk;

  // Reset task
  task automatic reset();
    begin
      prst_n = 0;
      {paddr, pwdata, psel, pwrite, penable, rdata, rack, wack, waddrerr, raddrerr} = 0;
      @(posedge pclk);
      @(posedge pclk);
      prst_n = 1;
    end
  endtask

  // Write task
  task automatic apb_write(input [11:0] addr, input [31:0] data);
    begin
      @(posedge pclk);
      paddr = addr;
      pwdata = data;
      psel = 1;
      pwrite = 1;
      penable = 0;
      @(posedge pclk);
      penable = 1;
      wait (dut.wr_en);
      @(posedge pclk);
      wack = 1;
      @(posedge pclk);
      wack = 0;
      psel = 0;
      penable = 0;
    end
  endtask

  // Read task
  task automatic apb_read(input [11:0] addr, input [31:0] expected_data);
    begin
      @(posedge pclk);
      paddr = addr;
      psel = 1;
      pwrite = 0;
      penable = 0;
      @(posedge pclk);
      penable = 1;
      wait (dut.rd_en);
      rdata = expected_data;
      @(posedge pclk);
      rack = 1;
      @(posedge pclk);
      rack = 0;
      psel = 0;
      penable = 0;

      if (prdata !== expected_data)
        $display("[READ FAIL] Got %h, expected %h", prdata, expected_data);
      else
        $display("[READ PASS] prdata = %h", prdata);
    end
  endtask

  // Address error test
  task automatic error_test();
    begin
      @(posedge pclk);
      waddrerr = 1;
      raddrerr = 1;
      @(posedge pclk);
      if (!pslverr)
        $display("[ERROR FAIL] pslverr should be 1");
      else
        $display("[ERROR PASS] pslverr = 1");
      waddrerr = 0;
      raddrerr = 0;
    end
  endtask

  initial begin
    reset();

    // Test cases
    apb_write(12'h100, 32'hDEADBEEF);
    apb_read(12'h100, 32'hDEADBEEF);
    error_test();

    #20;
    $finish;
  end

endmodule