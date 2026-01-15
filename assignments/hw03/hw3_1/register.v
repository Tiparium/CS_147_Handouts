/*
   CS 147, Spring 26
   Homework #3, Problem #1

   Parameterized N-bit register built from 1-bit DFFs.
*/
module register (
                 // Outputs
                 q, err,
                 // Inputs
                 clk, rst, en, d
                 );

   parameter WIDTH = 16;

   input              clk, rst, en;
   input  [WIDTH-1:0] d;
   output [WIDTH-1:0] q;
   output             err;

   /* YOUR CODE HERE */

endmodule
