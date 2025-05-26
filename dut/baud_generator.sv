module baud_generator(
    input           clk,
    input           rst_n,
    input [10:0]    dvsr,
    output          tick
);
logic [10:0] r_reg;
logic [10:0] r_next;
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) 
        r_reg <= 0;
    else 
        r_reg <= r_next;
end
assign r_next = (r_reg == dvsr) ? 0 : r_reg + 1;
assign tick = (r_reg == 1);

endmodule