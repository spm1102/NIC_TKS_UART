module uart_rx(
    input               clk,
    input               tick,
    input               rst_n,

    input               rx,

    input [1:0]         data_bit_num,
    input               stop_bit_num,
    input               parity_en,
    input               parity_type,

    input               rd_en,
    input      [11:0]   raddr,

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

/// tin hieu giu rx_done cho den khi cpu doc 
logic rx_done_tmp;
logic host_rd;
logic rts_n_tmp;
assign host_rd = (rd_en && raddr == 12'b100) ? 1 : 0;
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
        IDLE: begin
            rts_n_tmp = 0;
            rx_done_tmp = 0;
        end
        START: begin
            rts_n_tmp = 1;
            rx_done_tmp = 0;
        end
        DATA:  begin
            rts_n_tmp = 1;
            rx_done_tmp = 0;
        end
        PARITY:  begin
            rts_n_tmp = 1;
            rx_done_tmp = 0;
        end
        STOP: begin
            if (next_state == IDLE) begin
                rx_done_tmp = 1;
                rts_n_tmp = 1;
            end
            else begin
                rx_done_tmp = 0;
                rts_n_tmp = 1;
            end
        end
        default:   begin 
            rts_n_tmp = 1;
            rx_done_tmp = 0;
        end
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
        //parity_bit <= 0;
        parity_error <= 0;
        //rx_done <= 0;
        rx_data <= 0;
    end else begin
        //rx_done <= 0;
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
                        count_data <= count_data + 1;
                        // tinh toan parity_bit de so sanh voi rx nhan vao sau
                        if (parity_type) begin
                            parity_calc <= parity_calc ^ rx;
                        end
                        else parity_calc <= ~(parity_calc ^ rx);
                    end
                end

                PARITY: begin
                    if (tick_cnt == 15) begin
                        //parity_bit <= (parity_type) ? ~parity_calc : parity_calc;
                        parity_error <= (rx != parity_calc);
                    end
                end

                STOP: begin
                    if (tick_cnt == 15) begin
                        count_stop <= count_stop + 1;
                        if (count_stop == num_stop - 1) begin 
                            //rx_done <= 1;
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

always_ff@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
    rx_done <= 0;
    end
    else begin
        if (rx_done_tmp) begin
            rx_done <= 1;
        end
        else if (host_rd) begin
            rx_done <= 0;
        end
        // else if (rx_done_flag) begin
        //     rx_done <= 1;
        // end
        else begin end
    end
end
assign rts_n = rx_done ? 1: rts_n_tmp;
endmodule
