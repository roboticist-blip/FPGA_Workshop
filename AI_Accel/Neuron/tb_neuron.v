`timescale 1ns/1ps

module tb_neuron;
    reg clk;
    reg rst;
    reg signed [15:0] I;
    reg signed [15:0] W;
    reg signed [31:0] B;
    wire signed [31:0]SUM;
    wire [31:0] OUT;

    neuron uut(.clk(clk),.rst(rst),.I(I),.W(W),.B(B),.OUT(OUT));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("neuron.vcd");
        $dumpvars(0, tb_neuron);
        $monitor("Time=%0t rst=%b I=%h W=%h bais=%h OUT=%d",$time, rst, I, W, B, OUT);

        rst = 0;
        I   = 0;
        W   = 0;
        B = 0;
        #12;

        rst = 0;
        I = {16'd0,4'd2,4'd4,4'd6,4'd8};
        W = {16'd0,4'd3,4'd5,4'd7,4'd9};
        B = -200;
        #20;

        rst = 1;
        I = {16'd0,4'd3,4'd4,4'd5,4'd6};
        W = {16'd0,4'd3,4'd4,4'd5,4'd6};
        B = 32'd43;
        #20;

        rst = 0;
        I = {16'd0,4'd1,4'd2,4'd3,4'd4};
        W = {16'd0,4'd8,4'd7,4'd6,4'd5};
        B = 32'd43;
        #20;

        $finish;

    end
endmodule
