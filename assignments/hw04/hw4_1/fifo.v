/* $Author: karu $ */
/* $LastChangedDate: 2009-03-04 23:09:45 -0600 (Wed, 04 Mar 2009) $ */
/* $Rev: 45 $ */
module fifo(/*AUTOARG*/
   // Outputs
   data_out, fifo_empty, fifo_full, err,
   // Inputs
   data_in, data_in_valid, pop_fifo, clk, rst
   );
   input [63:0] data_in;
   input        data_in_valid;
   input        pop_fifo;

   input        clk;
   input        rst;
   output [63:0] data_out;
   output        fifo_empty;
   output        fifo_full;
   output        err;

   //your code here

endmodule
// DUMMY LINE FOR REV CONTROL :1:
