// fsm_ctrl.v
// Sequences the MLP pipeline. Each layer is combinational-dot-product + registered-output, so each layer takes exactly 1 clock edge to produce a valid result once its inputs are stable. This FSM exists to make that timing explicit and give a clean "done" pulse, rather than relying on the user to count cycles externally.
//
// States:
//   IDLE         - waiting for START
//   LOAD_INPUT   - input vector is presented to layer 1 this cycle
//   LAYER1_WAIT  - layer 1's registered outputs become valid on this edge
//   LAYER2_WAIT  - layer 2's registered outputs become valid on this edge
//   DONE         - output vector valid, DONE pulses high for 1 cycle

module fsm_ctrl (
    input  clk,
    input  rst,
    input  start,
    output reg done,
    output [2:0] state_out
);

    localparam IDLE        = 3'd0,
               LOAD_INPUT   = 3'd1,
               LAYER1_WAIT  = 3'd2,
               LAYER2_WAIT  = 3'd3,
               DONE_ST      = 3'd4;

    reg [2:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done  <= 1'b0;
        end
        else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    if (start)
                        state <= LOAD_INPUT;
                end

                LOAD_INPUT: begin
                    state <= LAYER1_WAIT;
                end

                LAYER1_WAIT: begin
                    state <= LAYER2_WAIT;
                end

                LAYER2_WAIT: begin
                    state <= DONE_ST;
                end

                DONE_ST: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    assign state_out = state;

endmodule
