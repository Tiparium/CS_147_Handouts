// 2:1 mux using continuous assignment
module mux2_continuous(
    input  wire sel,
    input  wire a,
    input  wire b,
    output wire y
);
assign y = sel ? b : a;
endmodule
