module Resgistor_block(
    input                               clk,
    input                               rst_n,

    input           [11:0]              waddr,
    input           [11:0]              raddr,
    input           [31:0]              wdata,
    input                               wr_en,
    input                               rd_en,

    input           [31:0]              rx_data,
    input                               tx_done,
    input                               rx_done,
    input                               parity_error,
    input                               start_tx_down,

    output logic    [7:0]               tx_data,

    output logic    [1:0]               data_bit_num,
    output logic                        stop_bit_num,
    output logic                        parity_en,
    output logic                        parity_type,

    output logic                        start_tx,

    output logic    [31:0]              rdata,
    output logic                        rack,
    output logic                        wack,
    output logic                        waddrerr,
    output logic                        raddrerr

); 

    wire tx_data_reg_ren;
    wire tx_data_reg_wen;
    wire rx_data_reg_ren;
    // wire rx_data_reg_wen;
    wire cfg_reg_ren;
    wire cfg_reg_wen;
    wire ctrl_reg_ren;
    wire ctrl_reg_wen;
    wire stt_reg_ren;
    // wire stt_reg_wen;

    logic [31:0] mux_tx_data;
    logic [31:0] mux_rx_data;
    logic [31:0] mux_cfg;
    logic [31:0] mux_ctrl;
    logic [31:0] mux_stt;

    assign mux_tx_data [7:0]                    = tx_data;
    assign mux_tx_data [31:8]                   = '0;

    assign mux_rx_data [7:0]                    = rx_data;
    assign mux_rx_data [31:8]                   = '0;

    assign mux_cfg     [1:0]                    = data_bit_num;
    assign mux_cfg     [2]                      = stop_bit_num;
    assign mux_cfg     [3]                      = parity_en;
    assign mux_cfg     [4]                      = parity_type;
    assign mux_cfg     [31:5]                   = '0;   

    assign mux_ctrl    [0]                      = start_tx;
    assign mux_ctrl    [31:1]                   = '0; 

    assign mux_stt     [0]                      =  tx_done;
    assign mux_stt     [1]                      =  rx_done;
    assign mux_stt     [2]                      =  parity_error;
    assign mux_stt     [31:3]                   =  '0;
     
    // assign tx_data_reg_wen                      = wr_en & (waddr == 32'b0);

    // assign cfg_reg_wen                          = wr_en & (waddr == 32'b1000);                                                           
    // assign ctrl_reg_wen                         = wr_en & (waddr == 32'b1100);                                                                          


    // assign tx_data_reg_ren                      = rd_en & (raddr == 32'b0);
    // assign rx_data_reg_ren                      = rd_en & (raddr == 32'b100);
    // assign cfg_reg_ren                          = rd_en & (raddr == 32'b1000);                                                           
    // assign ctrl_reg_ren                         = rd_en & (raddr == 32'b1100);                                                                          
    // assign stt_reg_ren                          = rd_en & (raddr == 32'b10000);

    assign waddrerr                             = !((waddr == 32'b0) | (waddr == 32'b1000) | (waddr == 32'b1100));
    assign raddrerr                             = !((raddr == 32'b0) | (raddr == 32'b1000) | (raddr == 32'b1100) | (raddr == 32'b100) | (raddr == 32'b10000));

    always_ff @( posedge clk or negedge rst_n ) begin 
        if (~rst_n) begin
            tx_data                             <= 8'b0;
            data_bit_num                        <= 2'b0;
            stop_bit_num                        <= 1'b0;
            parity_en                           <= 1'b0;
            parity_type                         <= 1'b0;
            start_tx                            <= 1'b0;
            rdata                               <= 32'b0;
        end
        else if (start_tx_down) start_tx <= 0;
        else if (wr_en) begin
            case (waddr) 
                32'b0: tx_data                  <= wdata[7:0];
                32'b1000: begin
                    data_bit_num                <= wdata[1:0];
                    stop_bit_num                <= wdata[2];
                    parity_en                   <= wdata[3];
                    parity_type                 <= wdata [4];                                                                                                          
                end
                32'b1100: begin
                    start_tx                    <= wdata[0];
                end
                default: begin
                end
            endcase
        end
        else if (rd_en) begin
            case (raddr) 
                32'b0: rdata                    <= mux_tx_data;
                32'b100: rdata                  <= mux_rx_data;
                32'b1000: rdata                 <= mux_cfg;                                                                                                
                32'b1100: rdata                 <= mux_ctrl;
                32'b10000: rdata                <= mux_stt;
                default: begin
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wack <= 0;
        end
        else if (wr_en) wack <= 1;
        else begin
            wack <= 0;
        end
    end


    // always_ff @(posedge clk or negedge rst_n) begin
    //     if (~rst_n) begin
    //         rack <= 0;
    //     end
    //     else if (rd_en) rack <= 1;
    //     else begin
    //         rack <= 0;
    //     end
    // end
assign rack = rd_en ? 1 : 0;


endmodule