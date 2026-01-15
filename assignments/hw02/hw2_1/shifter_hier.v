/*
    CS 147 Spring 26
    Homework #2, problem 1

    Wrapper around the shifter for testing.
*/
module shifter_hier(In, ShAmt, Oper, Out);

    // declare constant for size of inputs, outputs, and # bits to shift
    parameter OPERAND_WIDTH  = 16;
    parameter SHAMT_WIDTH    =  4;
    parameter NUM_OPERATIONS =  2;   

    input  [OPERAND_WIDTH -1:0] In   ; 
    input  [SHAMT_WIDTH   -1:0] ShAmt; 
    input  [NUM_OPERATIONS-1:0] Oper ; 
    output [OPERAND_WIDTH -1:0] Out  ; 

    // Signals for clkrst module
    wire clk;
    wire rst;
    wire err;

    assign err = 1'b0;
   
    shifter #(.OPERAND_WIDTH(OPERAND_WIDTH),
              .SHAMT_WIDTH(SHAMT_WIDTH),
              .NUM_OPERATIONS(NUM_OPERATIONS)) 
            DUT (.In(In), .ShAmt(ShAmt), .Oper(Oper), .Out(Out));

    clkrst c0(.clk(clk),
              .rst(rst),
              .err(err));
   
endmodule // shifter_hier
