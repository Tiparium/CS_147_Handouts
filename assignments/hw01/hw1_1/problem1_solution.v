// TODO: Implement the muxes using only nand/nor/not primitives from this folder.

module mux2_1 (
    input  InA,
    input  InB,
    input  S,
    output Out
);
    // TODO: implement 1-bit 2:1 mux
endmodule

module mux4_1 (
    input  InA,
    input  InB,
    input  InC,
    input  InD,
    input  [1:0] S,
    output Out
);
    // TODO: build from mux2_1 instances
endmodule

module quadmux4_1 (
    input  [3:0] InA,
    input  [3:0] InB,
    input  [3:0] InC,
    input  [3:0] InD,
    input  [1:0] S,
    output [3:0] Out
);
    // TODO: build from mux4_1 instances
endmodule
