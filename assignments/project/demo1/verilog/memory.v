/*
   CS 147 Spring 26
  
   Filename        : memory.v
   Description     : This module contains all components in the Memory stage of the 
                     processor.
*/
`default_nettype none
module memory (
   input  wire        clk,
   input  wire        rst,
   input  wire        memRead_in,
   input  wire        memReadorWrite_in,
   input  wire        memWrite_in,
   input  wire [15:0] aluResult_in,
   input  wire [15:0] writeData_in,
   input  wire        halt_in,
   output wire        memRead,
   output wire        memReadorWrite,
   output wire        memWrite,
   output wire [15:0] aluResult,
   output wire [15:0] writeData,
   output wire        halt
);

   // TODO: Your code here (stub outputs for testbench binding)
   assign memRead = memRead_in;
   assign memReadorWrite = memReadorWrite_in;
   assign memWrite = memWrite_in;
   assign aluResult = aluResult_in;
   assign writeData = writeData_in;
   assign halt = halt_in;

endmodule
`default_nettype wire
