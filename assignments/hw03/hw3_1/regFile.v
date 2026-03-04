/*
    CS 147 Spring 26
    Homework #3, problem 1

    8x16 register file with 2 read ports and 1 write port.
*/
// Shared via symlink between assignments/hw03/hw3_1/regFile.v and assignments/hw03/hw3_2/regFile.v.
// WARNING: This file can be edited from either path, but DO NOT move or duplicate this file.
module regFile (
                // Outputs
                read1Data, read2Data, err,
                // Inputs
                clk, rst, read1RegSel, read2RegSel, writeRegSel, writeData, writeEn
                );

   input        clk, rst;
   input [2:0]  read1RegSel;
   input [2:0]  read2RegSel;
   input [2:0]  writeRegSel;
   input [15:0] writeData;
   input        writeEn;

   output [15:0] read1Data;
   output [15:0] read2Data;
   output        err;

   /* YOUR CODE HERE */

endmodule
