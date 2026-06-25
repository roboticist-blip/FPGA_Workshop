`timescale 1ns/1ps

module tb_Mac_unit;

reg  [3:0] A;
reg  [3:0] B;
reg  [7:0] ACC;
wire [7:0] OUT;

Mac_unit uut (
    .A(A),
    .B(B),
    .ACC(ACC),
    .OUT(OUT)
);

initial begin

    $dumpfile("mac.vcd");
    $dumpvars(0, tb_Mac_unit);

    $monitor("Time=%0t A=%d B=%d ACC=%d OUT=%d",
             $time, A, B, ACC, OUT);

    // Test 1
    A = 4'd3;
    B = 4'd5;
    ACC = 8'd10;
    #10;

    // Test 2
    A = 4'd4;
    B = 4'd2;
    ACC = 8'd1;
    #10;

    // Test 3
    A = 4'd7;
    B = 4'd6;
    ACC = 8'd20;
    #10;

    $finish;
end

endmodule
