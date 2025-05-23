module uart_tx(
    input               clk,
    input               tick,
    input               rst_n,

    input [7:0]         tx_data,

    input               start_tx,
    input [1:0]         data_bit_num,
    input               stop_bit_num,
    input               parity_en,
    input               parity_type,

    input               cts_n,

    output logic        tx,
    output logic        tx_done,
    output logic        rts_n

);
typedef enum {IDLE, START, DATA, STOP} state_t;
// localparam IDLE = 2'h0;
// localparam START = 2'h1;
// localparam DATA = 2'h2;
// localparam STOP = 2'h3;


state_t current_state, next_state;

logic [3:0] num_data;
logic [1:0] num_stop;

logic start_send;
logic [3:0] count_data;
logic [1:0] count_stop;
logic [2:0] count_data_bit1;


logic parity_bit;

logic [3:0] tick_cnt;

// Mach com giai ma dau vao 
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

assign start_send = start_tx & (~cts_n) ;

assign rts_n = ~start_tx;

// Mach com tinh toan trang thai tiep theo
always_comb begin
    if (tick) begin
            case (current_state)
            IDLE: begin
                if (start_send) next_state = START;
                else next_state = IDLE;
            end
            START: begin
                if (tick_cnt == 4'b1111) begin 
                next_state = DATA;
                end
                else begin end
            end
            DATA: begin
                if (tick_cnt == 4'b1111) begin 
                    if (count_data == num_data + parity_en - 1) next_state = STOP;
                    else next_state = DATA;
                end
                else begin end
            end
            STOP: begin
                if (tick_cnt == 4'b1111) begin 
                    if (count_stop == num_stop - 1) next_state = IDLE;
                    else next_state = STOP;
                end
                else begin end
            end
            default: begin
                next_state = IDLE;
            end
            endcase 

    end
    else begin end
end

// Mach ff chuyen trang thai
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        current_state <= IDLE;
    end
    else if (tick) current_state <= next_state; 
    else begin end
end

// Mach ff tang cac bien dem
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        count_data <= 0;
        count_stop <= 0;
        count_data_bit1 <= 0;
        tick_cnt <= 0;
    end
    else begin
        if (tick) begin
            if (tick_cnt == 4'b1111)begin
                case (current_state) 
                DATA: begin
                    if (tx_data[count_data]) begin
                        count_data_bit1 <= count_data_bit1 + 1;
                        count_data <= count_data + 1;
                        count_stop <= 0;
                        tick_cnt <= 0;                
                    end
                    else begin
                        count_data <= count_data + 1;
                        count_stop <= 0;
                        tick_cnt <= 0;  
                    end
                end
                STOP: begin
                    count_stop <= count_stop + 1;
                    count_data <= 0;
                    tick_cnt <= 0;  
                end
                default: begin
                    count_stop <= 0;
                    count_data <= 0;
                    count_data_bit1 <= 0;
                    tick_cnt <= 0; 

                end
                endcase
            end
            else begin 
            tick_cnt <= tick_cnt + 1;
            end

        end
        else begin end
    end
end


// Mach com dau ra 
always_comb begin
    case (current_state)
    IDLE: begin
        tx = 1;
    end
    START: begin 
        tx = 0;
    end
    DATA: begin
        if (count_data == num_data ) tx = parity_bit;
        else tx = tx_data[count_data];
    end
    STOP: begin
        tx = 1;
    end
    default: begin
        tx = 1;
    end
    endcase 
end
always_ff @(posedge clk or negedge rst_n ) begin 
    if(~rst_n) tx_done <= 0;
    else begin
        if (tick) begin
        case (current_state) 
        STOP: begin
            if (next_state == IDLE) tx_done <= 1;
            else tx_done <= 0;
        end
        default: tx_done <= 0;
        endcase
        end
        else begin end
    end
end


endmodule