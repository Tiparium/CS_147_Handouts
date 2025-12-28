// 2:1 mux using procedural always block
module mux2_procedural(
    input  wire sel,
    input  wire a,
    input  wire b,
    output reg  y
);
always @* begin
    if (sel)
        y = b;
    else
        y = a;
end
endmodule
