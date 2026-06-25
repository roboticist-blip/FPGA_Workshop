// requant.v
// Converts one layer's wide accumulator outputs (ACC_W bits, post-ReLU) down to the narrow DW-bit signed format the next layer's neurons expect as input. This is the "requantization" step between layers.

// Method: saturate to the representable DW-bit signed range, rather than truncate. Truncating silently wraps large values to garbage; saturating clips them to the max/min representable value, which is the safer default for a first bring-up.

// NOTE: since this MLP uses ReLU, every value entering here is >= 0, so we only need to saturate the upper bound (no negative clipping needed here). Kept the lower bound check anyway for safety / reuse with non-ReLU layers.

module requant #(
    parameter N      = 4,   //layer width
    parameter ACC_W  = 32,  //incoming width\element
    parameter DW     = 8    //outgoing width\element
)(
    input  signed [N*ACC_W-1:0] IN_FLAT,
    output signed [N*DW-1:0]    OUT_FLAT
);

    localparam signed [DW-1:0] MAX_VAL = {1'b0, {DW-1{1'b1}}};
    localparam signed [DW-1:0] MIN_VAL = {1'b1, {DW-1{1'b0}}};

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : SAT
            wire signed [ACC_W-1:0] val = IN_FLAT[i*ACC_W +: ACC_W];

            assign OUT_FLAT[i*DW +: DW] =
                (val > $signed({{(ACC_W-DW){1'b0}}, MAX_VAL})) ? MAX_VAL :
                (val < $signed({{(ACC_W-DW){1'b1}}, MIN_VAL})) ? MIN_VAL :
                val[DW-1:0];
        end
    endgenerate

endmodule
