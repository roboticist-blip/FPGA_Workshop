module Mac_unit(
    input  [3:0] A,
    input  [3:0] B,
    input  [7:0] ACC,
    output [7:0] OUT
);

assign OUT = (A * B) + ACC;

endmodule
