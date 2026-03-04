// 2:1 mux using procedural always block
module mux2_procedural(
    input  wire sel,
    input  wire a,
    input  wire b,
    output reg  y
);
always @* begin
    case (sel)
        1'b0: y = a;
        1'b1: y = b;
        default: y = 1'bx; // should never happen
    endcase
end
endmodule
