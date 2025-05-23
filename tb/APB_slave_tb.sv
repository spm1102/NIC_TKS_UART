`timescale 1ns/1ps
module APB_slave_tb;

    // Signals
    logic pclk;
    logic prst_n;

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
    logic rd_en;

    // Instantiate DUT
    APB_slave dut (
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
        .wr_en(wr_en),
        .rd_en(rd_en)
    );

    // Clock generation 10ns period
    initial pclk = 0;
    always #5 pclk = ~pclk;

    // Reset task
    task reset_dut();
        begin
            prst_n = 0;
            psel = 0;
            penable = 0;
            pwrite = 0;
            pwdata = 0;
            paddr = 0;
            rdata = 0;
            rack = 0;
            wack = 0;
            waddrerr = 0;
            raddrerr = 0;
            @(posedge pclk);
            prst_n = 1;
            @(posedge pclk);
        end
    endtask

    // Write transaction task
    task write_transaction(input [11:0] addr, input [31:0] data);
        begin
            paddr = addr;
            pwdata = data;
            psel = 1;
            pwrite = 1;
            penable = 0;
            rack = 0;
            wack = 0;
            waddrerr = 0;
            raddrerr = 0;
            @(posedge pclk);
            penable = 1;
            @(posedge pclk);
            wack = 1;
            @(posedge pclk);
            wack = 0;
            psel = 0;
            penable = 0;
            @(posedge pclk);
        end
    endtask

    // Read transaction task
    task read_transaction(input [11:0] addr, input [31:0] data);
        begin
            paddr = addr;
            rdata = data;
            psel = 1;
            pwrite = 0;
            penable = 0;
            rack = 0;
            wack = 0;
            waddrerr = 0;
            raddrerr = 0;
            @(posedge pclk);
            penable = 1;
            @(posedge pclk);
            rack = 1;
            @(posedge pclk);
            rack = 0;
            psel = 0;
            penable = 0;
            @(posedge pclk);
        end
    endtask

    // Check expected values for write
    task check_write(input [11:0] expected_addr, input [31:0] expected_data);
        begin
            if (wr_en !== 1) $error("FAIL: wr_en expected 1 but got %b", wr_en);
            else if (waddr !== expected_addr) $error("FAIL: waddr expected 0x%03h but got 0x%03h", expected_addr, waddr);
            else if (wdata !== expected_data) $error("FAIL: wdata expected 0x%08h but got 0x%08h", expected_data, wdata);
            else $display("PASS: Write transaction passed.");
        end
    endtask

    // Check expected values for read
    task check_read(input [11:0] expected_addr, input [31:0] expected_data);
        begin
            if (rd_en !== 1) $error("FAIL: rd_en expected 1 but got %b", rd_en);
            else if (raddr !== expected_addr) $error("FAIL: raddr expected 0x%03h but got 0x%03h", expected_addr, raddr);
            else if (prdata !== expected_data) $error("FAIL: prdata expected 0x%08h but got 0x%08h", expected_data, prdata);
            else $display("PASS: Read transaction passed.");
        end
    endtask

    // Check error signals
    task check_error(input expected_pslverr);
        begin
            if (pslverr !== expected_pslverr) $error("FAIL: pslverr expected %b but got %b", expected_pslverr, pslverr);
            else $display("PASS: pslverr signal correct (%b)", pslverr);
        end
    endtask

    initial begin
        $dumpfile("APB_slave_tb.vcd");
        $dumpvars(0, APB_slave_tb);

        reset_dut();

        // Test case 1: Write valid
        write_transaction(12'h100, 32'hDEADBEEF);
        check_write(12'h100, 32'hDEADBEEF);

        // Test case 2: Read valid
        read_transaction(12'h200, 32'hCAFEBABE);
        check_read(12'h200, 32'hCAFEBABE);

        // Test case 3: Write with waddrerr = 1
        psel = 1; pwrite = 1; penable = 1; waddrerr = 1; raddrerr = 0;
        @(posedge pclk);
        check_error(1);
        psel = 0; penable = 0; waddrerr = 0;
        @(posedge pclk);

        // Test case 4: Read with raddrerr = 1
        psel = 1; pwrite = 0; penable = 1; waddrerr = 0; raddrerr = 1;
        @(posedge pclk);
        check_error(1);
        psel = 0; penable = 0; raddrerr = 0;
        @(posedge pclk);

        // Test case 5: Check pready when wack or rack is asserted
        // wack = 1
        psel = 1; pwrite = 1; penable = 1; wack = 1; rack = 0;
        @(posedge pclk);
        if (pready !== 1) $error("FAIL: pready expected 1 when wack=1");
        else $display("PASS: pready correct when wack=1");
        wack = 0;
        @(posedge pclk);

        // rack = 1
        psel = 1; pwrite = 0; penable = 1; rack = 1; wack = 0;
        @(posedge pclk);
        if (pready !== 1) $error("FAIL: pready expected 1 when rack=1");
        else $display("PASS: pready correct when rack=1");
        rack = 0;
        @(posedge pclk);

        // Neither wack nor rack
        psel = 1; penable = 1; wack = 0; rack = 0;
        @(posedge pclk);
        if (pready !== 0) $error("FAIL: pready expected 0 when wack=0 and rack=0");
        else $display("PASS: pready correct when wack=0 and rack=0");
        psel = 0; penable = 0;
        @(posedge pclk);

        $display("All tests done.");
        #100;
        $finish;
    end

endmodule
