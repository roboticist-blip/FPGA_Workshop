// ---------------------------------------------------------------------------
// neuron_layer.v
//
// One fully-connected layer: N_OUT neurons, each fully connected to the
// same N_IN-wide input vector. All neurons computed in parallel (separate
// multiplier hardware per neuron, no time-multiplexing).
//
// Weight/bias layout convention:
//   W_FLAT is N_OUT blocks of (N_IN*DW) bits, one block per neuron:
//     neuron j's weights = W_FLAT[ j*N_IN*DW +: N_IN*DW ]
//   B_FLAT is N_OUT blocks of ACC_W bits, one per neuron's bias.
// ---------------------------------------------------------------------------
module neuron_layer #(
    parameter N_IN   = 4,   // inputs per neuron (= width of input vector)
    parameter N_OUT  = 4,   // number of neurons in this layer
    parameter DW     = 8,   // bit width of each input/weight element
    parameter ACC_W  = 32   // accumulator / output width
)(
    input                                   clk,
    input                                   rst,
    input  signed [N_IN*DW-1:0]             X,       // shared input vector
    input  signed [N_OUT*N_IN*DW-1:0]       W_FLAT,  // all neurons' weights
    input  signed [N_OUT*ACC_W-1:0]         B_FLAT,  // all neurons' biases
    output signed [N_OUT*ACC_W-1:0]         Y_FLAT   // all neurons' outputs
);

    genvar j;
    generate
        for (j = 0; j < N_OUT; j = j + 1) begin : NEURON
            neuron #(
                .N     (N_IN),
                .DW    (DW),
                .ACC_W (ACC_W)
            ) u_neuron (
                .clk (clk),
                .rst (rst),
                .X   (X),
                .W   (W_FLAT[ j*N_IN*DW +: N_IN*DW ]),
                .B   (B_FLAT[ j*ACC_W   +: ACC_W   ]),
                .OUT (Y_FLAT[ j*ACC_W   +: ACC_W   ])
            );
        end
    endgenerate

endmodule
