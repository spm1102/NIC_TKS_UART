module uart_rx(
    input               clk,
    input               tick,
    input               rst_n,

    input               rx,

    input [1:0]         data_bit_num,
    input               stop_bit_num,
    input               parity_en,
    input               parity_type,

    output logic        rts_n,

    output logic        rx_done,
    output logic        parity_error,
    output logic [7:0]  rx_data
);

typedef enum logic [2:0] {IDLE, START, DATA, PARITY, STOP} state_t;
state_t current_state, next_state;

logic [3:0] num_data;
logic [1:0] num_stop;
logic [3:0] count_data;
logic [1:0] count_stop;
logic [4:0] tick_cnt;
logic [7:0] rx_shift;
logic parity_calc, parity_bit;

// Decode data bit number
always_comb begin
    case (data_bit_num)
        2'b00: num_data = 5;
        2'b01: num_data = 6;
        2'b10: num_data = 7;
        2'b11: num_data = 8;
        default: num_data = 5;
    endcase
end

// Decode stop bit number
always_comb begin
    num_stop = stop_bit_num ? 2 : 1;
end

// Next state logic
always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (~rx) next_state = START;
            else begin end
        end
        START: begin
            if (tick && tick_cnt == 7)
                next_state = DATA;
            else begin end
        end
        DATA: begin
            if (tick && tick_cnt == 15 && count_data == num_data - 1)
                next_state = (parity_en) ? PARITY : STOP;
            else begin end
        end
        PARITY: begin
            if (tick && tick_cnt == 15)
                next_state = STOP;
            else begin end
        end
        STOP: begin
            if (tick && tick_cnt == 15 && count_stop == num_stop - 1)
                next_state = IDLE;
            else begin end
        end
    endcase
end

// State transition
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end
always_comb begin
    case (current_state) 
        IDLE:       rts_n = 1;
        START:      rts_n = 0;
        DATA:       rts_n = 0;
        PARITY:     rts_n = 0;
        STOP:       rts_n = 0;
        default:    rts_n = 0;
    endcase
end

// Output and internal logic
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tick_cnt <= 0;
        count_data <= 0;
        count_stop <= 0;
        rx_shift <= 0;
        parity_calc <= 0;
        parity_bit <= 0;
        parity_error <= 0;
        rx_done <= 0;
        rx_data <= 0;
    end else begin
        rx_done <= 0;
        if (tick) begin
            if (current_state != IDLE && tick_cnt == 15)
                tick_cnt <= 0;
            else if (current_state != IDLE)
                tick_cnt <= tick_cnt + 1;

            case (current_state)
                START: begin
                    if (next_state == DATA) begin
                        tick_cnt <= 0;
                    end
                end

                DATA: begin
                    if (tick_cnt == 15) begin
                        rx_shift[count_data] <= rx;
                        parity_calc <= parity_calc ^ rx;
                        count_data <= count_data + 1;
                    end
                end

                PARITY: begin
                    if (tick_cnt == 15) begin
                        parity_bit <= (parity_type) ? ~parity_calc : parity_calc;
                        parity_error <= (rx != ((parity_type) ? ~parity_calc : parity_calc));
                    end
                end

                STOP: begin
                    if (tick_cnt == 15) begin
                        count_stop <= count_stop + 1;
                        if (count_stop == num_stop - 1) begin 
                            rx_done <= 1;
                            rx_data <= rx_shift;
                        end
                        else begin end
                    end
                    else begin end
                end

                IDLE: begin
                    tick_cnt <= 0;
                    count_data <= 0;
                    count_stop <= 0;
                    rx_shift <= 0;
                    parity_calc <= 0;
                    parity_error <= 0;
                end
            endcase
        end
    end
end

endmodule
