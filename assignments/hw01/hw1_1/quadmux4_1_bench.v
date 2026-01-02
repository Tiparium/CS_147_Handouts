module quadmux4_1_bench;

      // No inputs and outputs : testbenchs just a wrapper.

      // reg/wire definitions, we'll use these to drive our inputs and capture our outputs
   reg [3:0] InA;

   reg [3:0] InB;

   reg [3:0] InC;

   reg [3:0] InD;

   reg [1:0] S;

   wire [3:0] Out;

   wire Clk;
   //2 dummy wires
   wire rst;
   wire err;

//clkrst module instantiation
clkrst my_clkrst( .clk(Clk), .rst(rst), .err(err));

      // Module instantiation :
   quadmux4_1 DUT (.InA(InA), .InB(InB),.InC(InC),.InD(InD), .S(S), .Out(Out));

      // Input drivers :
      //  Check every combination of S

      // Whatever you put within an initial block will be executed
      // when simulation starts
   initial
     begin
	     // Lets initialize all inputs (We dont want any 'Z's)
	InA = 4'b0001;
	InB = 4'b1000;
	InC = 4'b1010;
	InD = 4'b0101;
        S = 2'b00;
	         // #10 means wait for a delay of 10 ticks.
	         // By doing this we hold every singal for some time, which allows
	         // for the combinational logical delay and for the output to be computed
	
	
	#3200    $finish;
	

     end // initial begin
      // The test is not complete (we didnt check every combination of all inputs, InA for example. But we can be pretty confident if this much works.

//Random values 
always@(posedge Clk) 
     begin
        InA = $random;
	InB = $random;
	InC = $random;
	InD = $random;
        S = $random;
     end

//always@(posedge Clk) S = S + 1;
// Output monitors
   always@(negedge Clk)
       // Sensitivity list ^^^ tells Modelsim what this always block is "sensitive" to.
       // Try to figure out what happens if you didnt include lets say InC...
           // Whenever any of these signals change, this block will execute
     begin
	case (S)
	    // This is a behavior description of what the mux is supposed to do...
	    // For every combination of S :
	  2'b00 : 
	    if (Out !== InA) $display ("ERRORCHECK InA S=0");
	  2'b01 : 
	    if (Out !== InB) $display ("ERRORCHECK InB S=1");  
	  2'b10 :
	    if (Out !== InC) $display ("ERRORCHECK InC S=2");
	  2'b11 : 
	    if (Out !== InD) $display ("ERRORCHECK InD S=3");
	  
	endcase // case (S)
     end // always@ (S, InA, InB, InC, InD, Out)

   endmodule // End of module : tb_quadmux4to1
