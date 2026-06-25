// weights_l1.v
// Hardcoded weights + biases for Layer 1 (hidden layer): 4 inputs -> 4 neurons. Values chosen to be small and hand-checkable, NOT trained weights.

// Layout: neuron j's 4 weights are W_FLAT[ j*4*DW +: 4*DW ], stored with element 0 in the lowest bits (matches X[0*DW +: DW] convention in neuron.v).

// Neuron 0 weights: [1, 1, 1, 1]   bias =  0
// Neuron 1 weights: [1,-1, 1,-1]   bias =  0
// Neuron 2 weights: [2, 0, 0, 0]   bias = -3
// Neuron 3 weights: [0, 0, 0, 2]   bias =  1

module weights_l1 #(
    parameter DW    = 8,
    parameter ACC_W = 32
)(
    output signed [4*4*DW-1:0] W_FLAT,   // 4 neurons x 4 weights x DW bits
    output signed [4*ACC_W-1:0] B_FLAT   // 4 neurons x ACC_W bits
);

    // Neuron 0: w = [1,1,1,1], b = 0
    assign W_FLAT[ 0*4*DW +: 4*DW ] = { 8'sd1, 8'sd1, 8'sd1, 8'sd1 };
    assign B_FLAT[ 0*ACC_W +: ACC_W ] = 32'sd0;

    // Neuron 1: w = [1,-1,1,-1], b = 0
    assign W_FLAT[ 1*4*DW +: 4*DW ] = { -8'sd1, 8'sd1, -8'sd1, 8'sd1 };
    assign B_FLAT[ 1*ACC_W +: ACC_W ] = 32'sd0;

    // Neuron 2: w = [2,0,0,0], b = -3
    assign W_FLAT[ 2*4*DW +: 4*DW ] = { 8'sd0, 8'sd0, 8'sd0, 8'sd2 };
    assign B_FLAT[ 2*ACC_W +: ACC_W ] = -32'sd3;

    // Neuron 3: w = [0,0,0,2], b = 1
    assign W_FLAT[ 3*4*DW +: 4*DW ] = { 8'sd2, 8'sd0, 8'sd0, 8'sd0 };
    assign B_FLAT[ 3*ACC_W +: ACC_W ] = 32'sd1;

endmodule
