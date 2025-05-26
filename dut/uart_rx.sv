module uart_rx(
    input               clk,
    input               tick,
    input               rst_n,

    input               rx,

    input [1:0]         data_bit_num,
    input               stop_bit_num,
    input               parity_en,
    input               parity_type,

    input               rts_n,

    output logic        rx_done,
    output logic        cts_n,
    output              parity_error,
    output [7:0]        rx_data
);
typedef enum {IDLE, START, DATA, STOP} state_t;
state_t current_state, next_state;


logic [3:0] num_data;
logic [1:0] num_stop;

logic [3:0] count_data;
logic [1:0] count_stop;

logic [2:0] count_data_bit1;
logic [3:0] tick_cnt;

always_comb begin
    case (data_bit_num) 
    2'b00: num_data = 4'h5;
    2'b01: num_data = 4'h6;
    2'b10: num_data = 4'h7;
    2'b11: num_data = 4'h8;
    default: num_data = 4'h0;
    endcase
end

always_comb begin
    if (stop_bit_num) num_stop = 2;
    else num_stop = 1;
end

always_comb begin
    if (parity_type) begin
        if (count_data_bit1[0]) parity_bit = 0;
        else parity_bit = 1;
    end
    else begin
        if (count_data_bit1[0]) parity_bit = 1;
        else parity_bit = 0;
    end
    
end
always_comb begin
    case (current_state) 
    IDLE: begin
        if (~rx) next_state = START;
        else begin end
    end
    START: begin
        if (tick) begin
            if (tick_cnt == 7) next_state = DATA;
            else begin 
                
            end


        end
    end
    endcase
end
endmodule