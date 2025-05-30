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

    output logic        start_tx_down
    // output logic        rts_n

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
logic [3:0] count_data; // dem so chu ki o trang thai data
logic [1:0] count_stop; // dem so chu ki o trang thai stop
// logic [2:0] count_data_bit1; // dem so bit 1 de tinh parity


logic parity_bit; // bit parity

logic [3:0] tick_cnt; // dem so tick de truyen data (du 16 tick thi moi truyen 1 bit)

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
    if (~parity_type) // odd parity
        parity_bit = ~^tx_data;
    else             // even parity
        parity_bit = ^tx_data;
end
// khi co start tx voi ben kia chuan bi nhan (cts_n) thi moi gui 
assign start_send = start_tx & (~cts_n) ;

// assign rts_n = ~start_send; // tin hieu nay chua nho, cap nhat sau

// Mach com tinh toan trang thai tiep theo
always_comb begin
        case (current_state)
            IDLE: begin
                if (start_send) next_state = START;
                else begin end;
            end
            START: begin
                if (tick) begin
                    if (tick_cnt == 4'b1111) begin 
                        next_state = DATA;
                    end
                    else begin end
                end 
                else begin end
            end
            DATA: begin
                if (tick) begin
                    if (tick_cnt == 4'b1111) begin 
                        if (count_data == num_data + parity_en - 1) next_state = STOP;
                        else next_state = DATA;
                    end
                    else begin end
                end
                else begin end
            end
            STOP: begin
                if (tick) begin
                    if (tick_cnt == 4'b1111) begin 
                        if (count_stop == num_stop - 1) next_state = IDLE;
                        else next_state = STOP;
                    end
                    else begin end
                end
                else begin end
            end
            default: begin
                next_state = IDLE;
            end
        endcase 

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
        // count_data_bit1 <= 0;
        tick_cnt <= 0;
    end
    else begin
        if (tick) begin
            if (tick_cnt == 4'b1111)begin
                case (current_state) 
                IDLE: begin
                    if (next_state == START) begin
                        count_stop <= 0;
                        count_data <= 0;
                        tick_cnt <= 0; 
                    end
                    else begin end
                end
                DATA: begin
                    count_data <= count_data + 1;
                    count_stop <= 0;
                    tick_cnt <= 0;  
                end
                STOP: begin
                    count_stop <= count_stop + 1;
                    count_data <= 0;
                    tick_cnt <= 0;  
                end
                default: begin
                    count_stop <= 0;
                    count_data <= 0;
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
        if (next_state == START) start_tx_down = 1;
        else start_tx_down = 0;
    end
    START: begin 
        tx = 0;
        start_tx_down = 0;
    end
    DATA: begin
        if (count_data == num_data ) tx = parity_bit;
        else tx = tx_data[count_data];
        start_tx_down = 0;
    end
    STOP: begin
        tx = 1;
        start_tx_down = 0;
    end
    default: begin
        tx = 1;
        start_tx_down = 0;
    end
    endcase 
end
// mach xu li tx_done
always_ff @(posedge clk or negedge rst_n ) begin 
    if(~rst_n) tx_done <= 0;
    else begin
        case (current_state)
        IDLE: begin
            tx_done <= 1;
        end 
        STOP: begin
            if (next_state == IDLE) tx_done <= 1;
            else tx_done <= 0;
        end
        default: tx_done <= 0;
        endcase
        
    end
end


endmodule