/*
   CS 147 Spring 26

   Filename        : regFile.v
   Description     : Stub register file interface for early testbench binding.
*/
`default_nettype none
module regFile (
   input  wire       write_in,
   input  wire [2:0] writeregsel_in,
   input  wire [15:0] writedata_in,
   output wire       write,
   output wire [2:0] writeregsel,
   output wire [15:0] writedata
);

   // TODO: Your code here (stub outputs for testbench binding)
   assign write = write_in;
   assign writeregsel = writeregsel_in;
   assign writedata = writedata_in;

endmodule
`default_nettype wire
