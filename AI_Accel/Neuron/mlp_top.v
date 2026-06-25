// mlp_top.v
// Top-level 4 -> 4 -> 2 MLP, fixed-point INT8 in/weights, INT32 accumulate, ReLU on both layers, hardcoded ROM weights.
// Pipeline (see fsm_ctrl.v for state timing):
//   X (4x8b) --> [layer1: 4 neurons, 4-wide dot] --> Y1 (4x32b, ReLU'd)
//             --> [requant: 32b -> 8b, saturating] --> Y1q (4x8b)
//             --> [layer2: 2 neurons, 4-wide dot] --> Y2 (2x32b, ReLU'd)
//                 = final output

module mlp_top #(
    parameter DW    = 8,
    parameter ACC_W = 32
)(
    input                        clk,
    input                        rst,
    input                        start,
    input  signed [4*DW-1:0]     X_IN,
    output signed [2*ACC_W-1:0]  Y_OUT,
    output                       done,
    output [2:0]                 dbg_state
);

    wire signed [4*4*DW-1:0]  l1_W;
    wire signed [4*ACC_W-1:0] l1_B;
    weights_l1 #(.DW(DW), .ACC_W(ACC_W)) u_w1 (.W_FLAT(l1_W), .B_FLAT(l1_B));

    wire signed [4*ACC_W-1:0] l1_Y;
    neuron_layer #(.N_IN(4), .N_OUT(4), .DW(DW), .ACC_W(ACC_W)) u_layer1 (
        .clk    (clk),
        .rst    (rst),
        .X      (X_IN),
        .W_FLAT (l1_W),
        .B_FLAT (l1_B),
        .Y_FLAT (l1_Y)
    );

//Requantize layer1's 32-bit outputs down to 8-bit for layer2
    wire signed [4*DW-1:0] l1_Yq;
    requant #(.N(4), .ACC_W(ACC_W), .DW(DW)) u_requant (
        .IN_FLAT  (l1_Y),
        .OUT_FLAT (l1_Yq)
    );

//Layer 2 weights/bias ROM
    wire signed [2*4*DW-1:0] l2_W;
    wire signed [2*ACC_W-1:0] l2_B;
    weights_l2 #(.DW(DW), .ACC_W(ACC_W)) u_w2 (.W_FLAT(l2_W), .B_FLAT(l2_B));

//Layer 2: 4 in -> 2 out
    neuron_layer #(.N_IN(4), .N_OUT(2), .DW(DW), .ACC_W(ACC_W)) u_layer2 (
        .clk    (clk),
        .rst    (rst),
        .X      (l1_Yq),
        .W_FLAT (l2_W),
        .B_FLAT (l2_B),
        .Y_FLAT (Y_OUT)
    );

    fsm_ctrl u_fsm (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .done      (done),
        .state_out (dbg_state)
    );

endmodule
