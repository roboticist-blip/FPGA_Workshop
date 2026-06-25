// weights_l2.v

// Hardcoded weights + biases for Layer 2 (output layer): 4 inputs -> 2 neurons.
// Inputs here are the requantized (8-bit) outputs of layer 1's neurons. Values chosen to be small and hand-checkable, NOT trained weights.

// Neuron 0 weights: [1, 1, 0, 0]   bias =  0
// Neuron 1 weights: [0, 0, 1, 1]   bias = -2

module weights_l2 #(
    parameter DW    = 8,
    parameter ACC_W = 32
)(
    output signed [2*4*DW-1:0] W_FLAT,   // 2 neurons x 4 weights x DW bits
    output signed [2*ACC_W-1:0] B_FLAT   // 2 neurons x ACC_W bits
);

    // Neuron 0: w = [1,1,0,0], b = 0
    assign W_FLAT[ 0*4*DW +: 4*DW ] = { 8'sd0, 8'sd0, 8'sd1, 8'sd1 };
    assign B_FLAT[ 0*ACC_W +: ACC_W ] = 32'sd0;

    // Neuron 1: w = [0,0,1,1], b = -2
    assign W_FLAT[ 1*4*DW +: 4*DW ] = { 8'sd1, 8'sd1, 8'sd0, 8'sd0 };
    assign B_FLAT[ 1*ACC_W +: ACC_W ] = -32'sd2;

endmodule
