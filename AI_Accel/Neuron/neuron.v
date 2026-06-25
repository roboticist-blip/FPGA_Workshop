// ---------------------------------------------------------------------------
// neuron.v
//
// Generic single neuron: OUT = ReLU( sum_i(X[i]*W[i]) + B )
//
// - N inputs, each DW bits wide (signed), flattened into one bus.
// - Dot product is fully combinational (generate-loop of multipliers +
//   adder tree), registered once at the output on the clock edge.
// - This generalizes AI_Accel/Mac/mac_dot.v and AI_Accel/Neuron/neuron.v,
//   which hardcoded N=4, DW=4 (nibble-packed). Same idea, parameterized.
// ---------------------------------------------------------------------------
module neuron #(
    parameter N      = 4,   // number of inputs to this neuron
    parameter DW     = 8,   // bit width of each input / weight element
    parameter ACC_W  = 32   // accumulator / output width
)(
    input                           clk,
    input                           rst,
    input  signed [N*DW-1:0]        X,   // flattened input vector, element i = X[i*DW +: DW]
    input  signed [N*DW-1:0]        W,   // flattened weight vector, element i = W[i*DW +: DW]
    input  signed [ACC_W-1:0]       B,   // bias
    output reg    signed [ACC_W-1:0] OUT // ReLU(dot + bias), registered
);

    // ---- per-element product, generate loop replaces hand-listed p0..p3 ----
    // each product needs 2*DW bits to not overflow (signed x signed)
    wire signed [2*DW-1:0] prod [0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : MULT
            assign prod[i] = $signed(X[i*DW +: DW]) * $signed(W[i*DW +: DW]);
        end
    endgenerate

    // ---- adder tree: sum all N products (combinational) ----
    integer k;
    reg signed [ACC_W-1:0] sum_comb;
    always @(*) begin
        sum_comb = {ACC_W{1'b0}};
        for (k = 0; k < N; k = k + 1) begin
            sum_comb = sum_comb + prod[k];
        end
        sum_comb = sum_comb + B;
    end

    // ---- registered ReLU on the clock edge ----
    always @(posedge clk or posedge rst) begin
        if (rst)
            OUT <= {ACC_W{1'b0}};
        else if (sum_comb < 0)
            OUT <= {ACC_W{1'b0}};
        else
            OUT <= sum_comb;
    end

endmodule
