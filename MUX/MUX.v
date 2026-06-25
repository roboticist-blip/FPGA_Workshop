module mux_4to1(
input [3:0]a,
input [1:0]sel,
output Y
);

assign Y = (sel == 2'b00) ? a[0]: (sel == 2'b01) ? a[1]:(sel == 2'b10) ? a[2]:a[3];
initial
begin
    $monitor("The output for %b is %b", sel, Y);
end
endmodule
