/*
    CS 147 Spring 26
    Homework #3, problem 1

    1-bit D flip-flop.
*/
module dff (
            // Output
            q,
            // Inputs
            d, clk, rst
            );

    output         q;
    input          d;
    input          clk;
    input          rst;

    reg            state;

    assign #(1) q = state;

    always @(posedge clk) begin
      state = rst? 0 : d;
    end

endmodule
