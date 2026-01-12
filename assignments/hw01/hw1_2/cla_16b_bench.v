module cla_16b_bench;
   reg [16:0] A;
   reg [16:0] B;
   reg [16:0] Sumcalc;
   reg        C_in;
   wire [15:0] SUM;
   wire        CO;
   wire        clk;
   //2 dummy wires
   wire        rst;
   wire        err;

   clkrst my_clkrst( .clk(clk), .rst(rst), .err(err));
   cla_16b DUT (.sum(SUM), .c_out(CO), .a(A[15:0]), .b(B[15:0]), .c_in(C_in));

   initial begin
      A = 17'b0_0000_0000_0000_0000;
      B = 17'b0_0000_0000_0000_0000;
      C_in = 1'b0;
      #3200 $finish;
   end
   
   always@(posedge clk) begin
      A[15:0] = $random;
      B[15:0] = $random;
      C_in = $random;
   end
   
   always@(negedge clk) begin
      Sumcalc = A+B+C_in;
      $display("A: %x, B: %x, Sum: %x, Golden Sum: %x", A, B, SUM, Sumcalc);

      if (Sumcalc[15:0] !== SUM) $display ("ERRORCHECK Sum error");
      if (Sumcalc[16] !== CO) $display ("ERRORCHECK CO error");
   end
endmodule // cla_16b_bench
