// TODO: Implement adders using the provided gate primitives (not1/nand/nor/xor).

module fulladder (
    input  A,
    input  B,
    input  Cin,
    output S,
    output Cout
);
    // TODO: 1-bit full adder (sum and carry)
endmodule

module fulladder4 (
    input  [3:0] A,
    input  [3:0] B,
    input        CI,
    output [3:0] SUM,
    output       CO
);
    // TODO: ripple-carry chain of fulladders
endmodule

module fulladder16 (
    input  [15:0] A,
    input  [15:0] B,
    output [15:0] SUM,
    output        CO
);
    // TODO: ripple-carry chain of fulladder4 blocks (no carry-in on top level)
endmodule
