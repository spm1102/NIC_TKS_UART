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
    output logic        parity_error,
    output logic [7:0]  rx_data
);
typedef enum logic [2:0] {IDLE, START, DATA, PARITY, STOP, DONE} state_t;
state_t current_state, next_state;


logic [3:0] num_data;
logic [1:0] num_stop;

logic [3:0] count_data;
logic [1:0] count_stop;

logic [4:0] tick_cnt;
logic [7:0] rx_shift;
logic parity_calc;
logic parity_bit;

always_comb begin
    case (data_bit_num) 
    2'b00: num_data = 4'h5;
    2'b01: num_data = 4'h6;
    2'b10: num_data = 4'h7;
    2'b11: num_data = 4'h8;
    default: num_data = 4'h0;
    endcase
end
// Map number of stop bits
always_comb begin
    if (stop_bit_num) num_stop = 2;
    else num_stop = 1;
end

// FSM: next state logic
always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if(~rx) next_state = START;
        end

        START: begin
            if (tick && tick_cnt == 7) //mid of start bit
                next_state = DATA;
        end

        DATA: begin
            if(tick && tick_cnt == 15 && count_data == num_data)
                next_state = (parity_en) ? PARITY : STOP;
        end

        PARITY: begin
            if( tick && tick_cnt == 15)
                next_state = STOP;
        end

        STOP: begin
            if(tick && tick_cnt == 15 && count_stop == num_stop)
                next_state = DONE;
        end

        DONE: begin
            next_state = IDLE;
        end
        default: begin
        end
    endcase
end

// FSM: state register
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

//Tick counter
always_ff @(posedge clk or negedge rst_n) begin
    if( !rst_n) tick_cnt <= 0;
    else if(tick) begin
        if(current_state == IDLE)
            tick_cnt <= 0;
        else if (current_state == START) begin
            if (next_state == DATA) tick_cnt <= 0;
            else tick_cnt <= tick_cnt + 1;
        end
        else if(tick_cnt == 15)
            tick_cnt <= 0;
        else
            tick_cnt <= tick_cnt + 1;
    end
end

//Data bit counter
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) count_data <= 0;
    else if (current_state == DATA && tick && tick_cnt == 15)
        count_data <= count_data + 1;
    else if (current_state == START)
        count_data <= 0;
    if(current_state == IDLE)
        count_data <= 0;
    
end

//Stop bit counter
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) count_stop <= 0;
    else if (current_state == STOP && tick && tick_cnt == 15)
        count_stop <= count_stop + 1;
    else if (current_state == IDLE)
        count_stop <= 0;
end

// Shift register for RX data
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) rx_shift <= 0;
    else if (current_state == DATA && tick && tick_cnt == 15)
        if (next_state == STOP) begin end
        else rx_shift[count_data]  <= rx;
    if(current_state == IDLE) rx_shift <= 0;
end

//Parity calculation
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) parity_calc <= 0;
    else if(current_state == START)
        parity_calc <= 0;
    else if( current_state == DATA && tick && tick_cnt == 15)
        parity_calc <= parity_calc ^ rx;
    if (current_state == IDLE)parity_calc <= 0;
end

//Parity checking
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
         parity_error <= 0;
         parity_bit <= 0;
    end
    else if(current_state == PARITY && tick && tick_cnt == 15) begin
        if(parity_type)
            parity_bit <= ~parity_calc;
        else
            parity_bit <= parity_calc;

        parity_error <= (rx != parity_bit);
    end
    if (current_state == IDLE) begin
        parity_bit <= 0;
        parity_error <= 0;

    end
end

//Output assignment
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_done <= 0;
        rx_data <= 0;
    end
    else begin
        if(current_state == DONE) begin
            rx_done <= 1;
            rx_data <= rx_shift;
        end else begin
            rx_done <= 0;
        end
    end
end

// CTS output
assign cts_n = 1'b0;


endmodule
// always_comb begin
//     if (parity_type) begin
//         if (count_data_bit1[0]) parity_bit = 0;
//         else parity_bit = 1;
//     end
//     else begin
//         if (count_data_bit1[0]) parity_bit = 1;
//         else parity_bit = 0;
//     end
    
// end
// always_comb begin
//     case (current_state) 
//     IDLE: begin
//         if (~rx) next_state = START;
//         else begin end
//     end
//     START: begin
//         if (tick) begin
//             if (tick_cnt == 7) next_state = DATA;
//             else begin 
                
//             end


//         end
//     end
//     endcase
// end