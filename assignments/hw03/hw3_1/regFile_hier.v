/*
   CS/ECE 552, Spring '22
   Homework #3, Problem #1
  
   Wrapper module around 8x16b register file.

   YOU SHALL NOT EDIT THIS FILE. ANY CHANGES TO THIS FILE WILL
   RESULT IN ZERO FOR THIS PROBLEM.
*/
module regFile_hier (
                     // Outputs
                     read1Data, read2Data, 
                     // Inputs
                     read1RegSel, read2RegSel, writeRegSel, writeData, writeEn
                     );

   input [2:0]  read1RegSel;
   input [2:0]  read2RegSel;
   input [2:0]  writeRegSel;
   input [15:0] writeData;
   input        writeEn;

   output [15:0] read1Data;
   output [15:0] read2Data;

   wire          clk, rst;
   wire          err;

   // Ignore err for now
   clkrst clk_generator(.clk(clk), .rst(rst), .err(err) );
   regFile rf0 (
                // Outputs
                .read1Data                    (read1Data[15:0]),
                .read2Data                    (read2Data[15:0]),
                .err                          (err),
                // Inputs
                .clk                          (clk),
                .rst                          (rst),
                .read1RegSel                  (read1RegSel[2:0]),
                .read2RegSel                  (read2RegSel[2:0]),
                .writeRegSel                  (writeRegSel[2:0]),
                .writeData                    (writeData[15:0]),
                .writeEn                      (writeEn));

endmodule
