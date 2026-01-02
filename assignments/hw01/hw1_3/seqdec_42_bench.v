module seqdec_42_bench;
   reg InA;
   wire Clk;
   wire Reset;
   wire Out;
   reg [127:0] sequenc;
   integer    k;
   reg [7:0]  seq;
   reg [7:0]  seqp1;

   wire err;
   assign err = 1'b0;

   seqdec_42 DUT (.InA(InA),.Clk(Clk),.Reset(Reset),.Out(Out));
   clkrst my_ckrst ( .clk(Clk), .rst(Reset), .err(err));

   always@(posedge Clk)
     begin
	if (Reset == 1'b1) 
	  begin
	     InA = 1'b0;
	     k = 0;
	     sequenc = 128'h0028_850A_972E_4284_5353_28A0_8597_4253;    // Sequence detection is for 85, 97, 42, 53, 28
	     seq = 8'h00;
	     seqp1 = 8'h00;
   
	  end
	else
	  begin
	     InA = sequenc[127-k];
	     k = k + 1;
	     seq[7:1] <= seq[6:0];
	     seq[0] <= InA;
	     seqp1 <= seq;
	     
	     if (k == 128) $finish;
	     
	  end
     end


   always@(negedge Clk)
     begin
	if ((Out !== 1'b1) && (seqp1 === 8'h42))
	  $display("ERRORCHECK :: Out not going to 1 as expected");
	if ((Out === 1'b1) && (seqp1 !== 8'h42))
	  $display("ERRORCHECK :: Out going to 1 unnexpected");
     end
endmodule
