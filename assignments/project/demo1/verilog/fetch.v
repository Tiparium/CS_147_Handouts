/*
   CS 147 Spring 26
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.
*/
`default_nettype none
module fetch (
   input  wire        clk,
   input  wire        rst,
   input  wire        pc_we,
   input  wire [15:0] pc_next,
   input  wire [15:0] instr_in,
   output wire [15:0] pcCurrent,
   output wire [15:0] instr
);

   // TODO: Your code here (stub outputs for testbench binding)
   assign pcCurrent = 16'h0000;
   assign instr = instr_in;

endmodule
`default_nettype wire
