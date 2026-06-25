`timescale 1ns/1ps

module tb_Mac_mult;

    reg clk;
    reg rst;
    reg [31:0] A;
    reg [31:0] B;
    wire [63:0] OUT;

    mac_mult uut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .OUT(OUT)
    );

    initial begin
        clk = 0;
        forever #5  clk = ~clk;
    end

    initial begin

        $dumpfile("mac_mult.vcd");
        $dumpvars(0, tb_Mac_mult);

        $monitor("Time=%0t rst=%b A=%d B=%d OUT=%d",
                  $time, rst, A, B, OUT);

        rst = 1;
        A   = 0;
        B   = 0;
        #12;

        rst = 0;
        A = 2;
        B = 3;
        #50;

        A = 4;
        B = 2;
        #50;

        rst = 1;
        #10;
        rst = 0;

        A = 5;
        B = 5;
        #50;

        $finish;
    end

endmodule
