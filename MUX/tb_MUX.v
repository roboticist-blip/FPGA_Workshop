 
`timescale 1ns/1ps

module tb;

reg [3:0] a;
reg [1:0] sel;
wire Y;

mux_4to1 uut(
    .a(a),
    .sel(sel),
    .Y(Y)
);

initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0,MUX);
    a = 4'b1010;

    $monitor("sel=%b Y=%b", sel, Y);

    sel = 2'b00; #10;
    sel = 2'b01; #10;
    sel = 2'b10; #10;
    sel = 2'b11; #10;

    $finish;
end

endmodule
