module mac_mult(
    input clk,
    input rst,
    input [3:0] A,
    input [3:0] B,
    output reg [15:0] OUT
);

always @(posedge clk or posedge rst) begin
    if(rst)
        OUT <= 0;
    else
        OUT <= OUT + (A * B);
end

endmodule
