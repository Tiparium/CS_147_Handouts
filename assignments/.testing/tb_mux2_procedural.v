`timescale 1ns/1ps

module tb_mux2_procedural;
  reg sel;
  reg a;
  reg b;
  wire y;

  mux2_procedural dut(
    .sel(sel),
    .a(a),
    .b(b),
    .y(y)
  );

  integer errors = 0;

  task check;
    input reg sel_i;
    input reg a_i;
    input reg b_i;
    input reg expected;
    begin
      sel = sel_i; a = a_i; b = b_i;
      #1;
      if (y !== expected) begin
        errors = errors + 1;
        $display("FAIL proc sel=%0b a=%0b b=%0b got=%0b expected=%0b", sel, a, b, y, expected);
      end
    end
  endtask

`ifdef DUMP
  initial begin
`ifdef DUMPFILE_PROC
    $dumpfile(`DUMPFILE_PROC);
`else
    $dumpfile("waves/mux2_procedural.vcd");
`endif
    $dumpvars(0, tb_mux2_procedural);
  end
`endif

  initial begin
    check(0, 0, 0, 0);
    check(0, 0, 1, 0);
    check(0, 1, 0, 1);
    check(0, 1, 1, 1);
    check(1, 0, 0, 0);
    check(1, 0, 1, 1);
    check(1, 1, 0, 0);
    check(1, 1, 1, 1);

    if (errors == 0) begin
      $display("PASS mux2_procedural");
      $finish;
    end else begin
      $display("FAIL mux2_procedural errors=%0d", errors);
      $finish_and_return(1);
    end
  end
endmodule
