/* $Author: sinclair $ */
/* $LastChangedDate: 2020-02-09 17:03:45 -0600 (Sun, 09 Feb 2020) $ */
/* $Rev: 46 $ */
`default_nettype none
module proc (/*AUTOARG*/
   // Outputs
   err, 
   // Inputs
   clk, rst
   );

   input wire clk;
   input wire rst;

   output reg err;

   // None of the above lines can be modified

   // OR all the err ouputs for every sub-module and assign it as this
   // err output
   
   // As desribed in the homeworks, use the err signal to trap corner
   // cases that you think are illegal in your statemachines
   
   
   /* your code here -- should include instantiations of fetch, decode, execute, mem and wb modules */
   
endmodule // proc
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :0:
