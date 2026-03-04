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
   
   
   // TODO: Your code here -- should include instantiations of fetch, decode, execute, mem and wb modules
   // Stub instances for early testbench binding.
   wire [15:0] pcCurrent;
   wire [15:0] instr;
   wire        wb_write;
   wire [2:0]  wb_writeregsel;
   wire [15:0] wb_writedata;
   wire        memRead_out;
   wire        memReadorWrite_out;
   wire        memWrite_out;
   wire [15:0] mem_aluResult;
   wire [15:0] mem_writeData;
   wire        mem_halt;

   fetch fetch0(
      .clk(clk),
      .rst(rst),
      .pc_we(1'b0),
      .pc_next(16'h0000),
      .instr_in(16'h0000),
      .pcCurrent(pcCurrent),
      .instr(instr)
   );

   decode decode0(
      .clk(clk),
      .rst(rst),
      .instr(instr),
      .write_in(wb_write),
      .writeregsel_in(wb_writeregsel),
      .writedata_in(wb_writedata)
   );

   execute execute0(
      .clk(clk),
      .rst(rst)
   );

   memory memory0(
      .clk(clk),
      .rst(rst),
      .memRead_in(memRead_out),
      .memReadorWrite_in(memReadorWrite_out),
      .memWrite_in(memWrite_out),
      .aluResult_in(mem_aluResult),
      .writeData_in(mem_writeData),
      .halt_in(mem_halt),
      .memRead(),
      .memReadorWrite(),
      .memWrite(),
      .aluResult(),
      .writeData(),
      .halt()
   );

   wb wb0(
      .clk(clk),
      .rst(rst)
   );
   
endmodule // proc
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :0:
