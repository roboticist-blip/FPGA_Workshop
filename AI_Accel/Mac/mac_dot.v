module mac_dot(
input clk,
input rst,
input signed [15:0]I,
input signed [15:0]W,
input signed [31:0]B,
output reg [31:0]OUT
);

wire [7:0] p0,p1,p2,p3;

assign p0 = I[15:12] * W[15:12];
assign p1 = I[11:8]  * W[11:8];
assign p2 = I[7:4]   * W[7:4];
assign p3 = I[3:0]   * W[3:0];

reg signed [15:0]SUM;

always @(posedge clk or posedge rst)
begin
    if(rst) begin
        SUM <= 0;
        OUT <= 0;
    end
    else begin
        SUM <= p0 + p1 + p2 + p3 + B;

        if(SUM < 0)
            OUT <= 0;
        else
            OUT <= SUM;
    end
end

endmodule
