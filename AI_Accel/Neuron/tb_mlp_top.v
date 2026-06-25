`timescale 1ns/1ps

module tb_mlp_top;

    parameter DW    = 8;
    parameter ACC_W = 32;

    reg clk;
    reg rst;
    reg start;
    reg signed [4*DW-1:0] X_IN;
    wire signed [2*ACC_W-1:0] Y_OUT;
    wire done;
    wire [2:0] dbg_state;

    mlp_top #(.DW(DW), .ACC_W(ACC_W)) uut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .X_IN      (X_IN),
        .Y_OUT     (Y_OUT),
        .done      (done),
        .dbg_state (dbg_state)
    );

    wire signed [ACC_W-1:0] y0 = Y_OUT[0*ACC_W +: ACC_W];
    wire signed [ACC_W-1:0] y1 = Y_OUT[1*ACC_W +: ACC_W];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mlp_top.vcd");
        $dumpvars(0, tb_mlp_top);

        $monitor("Time=%0t state=%0d done=%b X=%h y0=%0d y1=%0d",
                  $time, dbg_state, done, X_IN, y0, y1);

        rst   = 1;
        start = 0;
        X_IN  = 0;
        #12;
        rst = 0;
        #10;

        X_IN  = { 8'sd4, -8'sd1, 8'sd3, 8'sd2 };
        start = 1;
        #10;
        start = 0;

        // wait for done (3 clock edges per fsm_ctrl: LOAD_INPUT->L1->L2->DONE)
        #40;

        X_IN  = { 8'sd0, 8'sd0, 8'sd0, 8'sd0 };
        start = 1;
        #10;
        start = 0;
        #40;

        X_IN  = { 8'sd5, 8'sd5, 8'sd5, 8'sd5 };
        start = 1;
        #10;
        start = 0;
        #40;

        $finish;
    end

endmodule
