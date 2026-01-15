/*
   CS 147, Spring 26
   Homework #3, Problem #1

   Parameterized N-bit register built from 1-bit DFFs.
*/
// Shared via symlink between assignments/hw03/hw3_1/register.v and assignments/hw03/hw3_2/register.v.
// WARNING: This file can be edited from either path, but DO NOT move or duplicate this file.
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
