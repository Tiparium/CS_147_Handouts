/*
   CS 147 Spring 26
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
`default_nettype none
module decode (
   input wire        clk,
   input wire        rst,
   input wire [15:0] instr,
   input wire        write_in,
   input wire [2:0]  writeregsel_in,
   input wire [15:0] writedata_in
);

   // TODO: Your code here (stub regfile instance for testbench binding)
   regFile regFile0(
      .write_in(write_in),
      .writeregsel_in(writeregsel_in),
      .writedata_in(writedata_in),
      .write(),
      .writeregsel(),
      .writedata()
   );

endmodule
`default_nettype wire
