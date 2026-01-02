/* $Author: karu $ */
/* $LastChangedDate: 2009-03-04 23:09:45 -0600 (Wed, 04 Mar 2009) $ */
/* $Rev: 45 $ */

module sc_bench();
   reg ctr_rst;
   wire [2:0] out;

   wire       err;
   wire       clk;
   wire       rst;
   reg [3:0]  random_gen;
   reg [2:0]  expected_out;

   reg        fail;

   sc_hier DUT (.ctr_rst(ctr_rst), .out(out));
   // Pull out clk and rst from clkgenerator module
   assign               clk = DUT.clk_generator.clk;
   assign               rst = DUT.clk_generator.rst;

   initial begin
    fail = 0;
    $dumpvars;
	ctr_rst = 1'b0;
	#4800
    if (fail)
      $display("TEST FAILED");
    else
       $display("TEST PASSED");
    $finish;
   end

   // ref design :
   always @ (posedge clk or posedge rst)
     begin
	if (rst == 1'b1)
	  begin
	     expected_out <= 3'b000;
	  end
	else
	  if (ctr_rst == 1'b1)
	    begin
	       expected_out <= 3'b000;
	    end
	  else
	    begin
       if (expected_out != 3'b101)
		    begin
		       expected_out <= expected_out + 1;
		    end
	    end
     end

   always @ (posedge clk) begin
	random_gen = $random %2;
	if (random_gen == 1)
	  ctr_rst = 1'b1;
	else
	  ctr_rst = 1'b0;
   end

   always @ (posedge clk) begin
    #10;
    if ((expected_out !== out)) begin
      $display("ERRORCHECK :: ctr_rst = %d : out = %d : expected_out = %d", ctr_rst, out, expected_out);
      fail = 1;
    end
    else begin
      $display("OKAY :: ctr_rst = %d : out = expected_out = %d", ctr_rst, out);
    end
   end
endmodule
// DUMMY LINE FOR REV CONTROL :1:
