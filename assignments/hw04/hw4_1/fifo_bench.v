module fifo_bench;
  reg [63:0] data_in;
  reg        data_in_valid;
  reg        pop_fifo;

  wire [63:0] data_out;
  wire        fifo_empty;
  wire        fifo_full;

  reg         err;
  wire        clk;
  wire        rst;

  integer     cycle_count;

  reg fail;
  reg partial_fail;

  // wire [63:0]  data_in_gold;
  // wire 	data_in_valid_gold;
  // wire 	pop_fifo_gold;

  reg [63:0] data_out_gold;
  reg        fifo_empty_gold;
  reg        fifo_full_gold;
  reg        data_out_valid_gold;


  fifo_hier DUT ( // Outputs
                  data_out, fifo_empty, fifo_full,
                  // Inputs
                  data_in, data_in_valid, pop_fifo);

  assign               clk = DUT.clk_generator.clk;
  assign               rst = DUT.clk_generator.rst;

  // assign data_in_gold = data_in;
  // assign data_in_valid_gold = data_in_valid;
  // assign pop_fifo_gold = pop_fifo;

  always @ (posedge clk)
    begin
       // data_in[31:0] = $random;
       // data_in[63:32] = $random;
       // data_in_valid = $random % 2;
       // pop_fifo = $random % 2;
    end

  initial
    begin
       cycle_count = 0;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       data_in = '0;
       fifo_empty_gold = 1;
       fifo_full_gold = 0;
       data_out_valid_gold = 0;
       data_out_gold = '0;
       fail = 0;
       partial_fail = 0;

       @(negedge rst);

       // The following are randomly generated test cases. The outputs signals
       // correspond to outputs recorded from a "gold" (perfect) fifo
       // implementation.  All output signals from your module except
       // 'data_out_valid' must match the outputs recorded from the gold fifo
       // to pass this testbench.

       data_in = 64'h462df78c76d457ed;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h462df78c76d457ed;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hd513d2aae2f784c5;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hd513d2aae2f784c5;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h47ecdb8f8932d612;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd513d2aae2f784c5;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'he2ca4ec5f4007ae8;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hb2a7266596ab582d;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hb2a7266596ab582d;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h10642120c03b2280;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h8983b813cb203e96;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h8983b813cb203e96;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'heaa62ad5359fdd6b;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h8983b813cb203e96;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'he7c572cf0effe91d;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h8983b813cb203e96;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h9e314c3ce5730aca;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h8983b813cb203e96;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hec4b34d820c4b341;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'he7c572cf0effe91d;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h5b0265b675c50deb;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'he7c572cf0effe91d;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h150fdd2ade7502bc;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h150fdd2ade7502bc;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h27f2554f42f24185;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h150fdd2ade7502bc;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h0aaa4b15bf23327e;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h27f2554f42f24185;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h2635fb4c31230762;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0aaa4b15bf23327e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hdbcd60b77c6da9f8;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h0aaa4b15bf23327e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h44de3789adcbc05b;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h0aaa4b15bf23327e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'ha8c7fc51ebfec0d7;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h0aaa4b15bf23327e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'h6457edc8e12ccec2;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h2635fb4c31230762;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hbf05007e090cdb12;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hdbcd60b77c6da9f8;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'he9ebf6d30fd28f1f;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hdbcd60b77c6da9f8;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h248b4b492dda595b;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hdbcd60b77c6da9f8;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'hc33f38862c156358;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hdbcd60b77c6da9f8;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'h937dbc267d3599fa;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h44de3789adcbc05b;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hd9d292b39799a82f;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h44de3789adcbc05b;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'he59b36cb7bf8fdf7;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h44de3789adcbc05b;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'hf682e2ed14cfc129;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hbf05007e090cdb12;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hefbe94dfda8ae2b5;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hbf05007e090cdb12;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h15090b2ae8740cd0;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hbf05007e090cdb12;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'hcd5ebc9a6e5daddc;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'he9ebf6d30fd28f1f;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h2779e94e2b0eed56;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'he9ebf6d30fd28f1f;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h9c0e8a385b6fb9b6;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'he9ebf6d30fd28f1f;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'h49c65d934a74bf94;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hd9d292b39799a82f;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'ha6fcde4d6dcb69db;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hefbe94dfda8ae2b5;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h653b49cabb45e276;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h2779e94e2b0eed56;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h02749b04a3071a46;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'ha6fcde4d6dcb69db;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h44018d88da6ebab4;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h02749b04a3071a46;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h975c9c2ee3c530c7;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h02749b04a3071a46;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h149e0729fea7a6fd;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h02749b04a3071a46;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h9eb7c63ded3408da;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h02749b04a3071a46;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h5d7199bab9f50473;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h02749b04a3071a46;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h8d24f61a6a8e05d5;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h8d24f61a6a8e05d5;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h603921c04b273796;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h8d24f61a6a8e05d5;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h6e5f0fdc3e99837d;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h8d24f61a6a8e05d5;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hed8d80db3f5a9b7e;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hed8d80db3f5a9b7e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hb0bcee61fd28e4fa;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hb0bcee61fd28e4fa;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'ha863965043779186;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'ha863965043779186;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h60b175c1949a8a29;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'ha863965043779186;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hb98c427325b27b4b;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'ha863965043779186;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hd44b80a82758d14e;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h60b175c1949a8a29;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hf33466e6070bb90e;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h60b175c1949a8a29;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hc6b5f48d155a1d2a;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h60b175c1949a8a29;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h6464e3c8bccfa879;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hd44b80a82758d14e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'he3b7aec735a0c96b;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd44b80a82758d14e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h5c8295b96216abc4;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd44b80a82758d14e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hc33390863fbb3b7f;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd44b80a82758d14e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hdece5ebd19452132;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd44b80a82758d14e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h54a879a96543cfca;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd44b80a82758d14e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h85e51e0bfd8b6afb;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hf33466e6070bb90e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hbab148751b60e536;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h54a879a96543cfca;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hd73fb4ae4465e788;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h54a879a96543cfca;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h9684e02d1444df28;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h54a879a96543cfca;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h06b3050d8f1cf61e;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h54a879a96543cfca;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'hc3761c8668ae1bd1;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h85e51e0bfd8b6afb;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h29efe9536c44f9d8;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hbab148751b60e536;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h8273e204f166fae2;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hbab148751b60e536;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hdc0344b8093e4d12;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hd73fb4ae4465e788;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h15890f2bd0c5dca1;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd73fb4ae4465e788;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h50d5f9a113b55527;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd73fb4ae4465e788;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'hcb5c80962c2d2358;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd73fb4ae4465e788;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'hd8ace2b1cb227096;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h8273e204f166fae2;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h7ab11bf5158b2b2b;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hdc0344b8093e4d12;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hd3a8e4a74249ff84;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h15890f2bd0c5dca1;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h6de5bbdba4da5649;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h7ab11bf5158b2b2b;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h1546dd2ad0bc5ea1;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hd3a8e4a74249ff84;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hbe75427c41a10583;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd3a8e4a74249ff84;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hb7dfaa6fb455f268;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd3a8e4a74249ff84;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h207691401c719738;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hd3a8e4a74249ff84;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h602831c0e2bf1ac5;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h6de5bbdba4da5649;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h1e1c873cd86a6ab0;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h6de5bbdba4da5649;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hf0b14ee10aec3515;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hf0b14ee10aec3515;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hc336048664b5e3c9;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hc336048664b5e3c9;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'had67e25ac69da28d;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hc336048664b5e3c9;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hb8ade671060a5d0c;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hc336048664b5e3c9;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hcf14ce9efbdfc2f7;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'had67e25ac69da28d;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hd00b12a0902a3a20;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'had67e25ac69da28d;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h86dcf00d6e8af5dd;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hb8ade671060a5d0c;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hfef064fdcf63da9e;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h86dcf00d6e8af5dd;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h71c129e381c39a03;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hfef064fdcf63da9e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hca9cbc9522119f44;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h71c129e381c39a03;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h7c1e5bf8297a1552;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h71c129e381c39a03;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h236afd464219e784;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h71c129e381c39a03;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h352d616a0beac117;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h71c129e381c39a03;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hb05202603e6f0f7c;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h7c1e5bf8297a1552;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h92831e25d31dfea6;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h7c1e5bf8297a1552;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h8a64b014a48f7c49;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h8a64b014a48f7c49;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h23907547ae68305c;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h6851e5d0da058ab4;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hb522406a03e9b707;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hb522406a03e9b707;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h39e48173a5e79e4b;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h64e165c9520eefa4;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h64e165c9520eefa4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h33836567ea5814d4;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h64e165c9520eefa4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h24d2bf4941103982;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h64e165c9520eefa4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h49b16f938e054c1c;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h64e165c9520eefa4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'haed72e5de471f8c8;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h64e165c9520eefa4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b0;

       data_in = 64'h1c8d7f3995a9a82b;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h64e165c9520eefa4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'he82b96d02c848959;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h33836567ea5814d4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h535277a66d8b87db;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h33836567ea5814d4;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'hb4e8d66987e44c0f;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h24d2bf4941103982;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h67d735cf62fd49c5;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h49b16f938e054c1c;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h3b83cd77b4f9a469;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h49b16f938e054c1c;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'he20e9ac44ddd4d9b;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h535277a66d8b87db;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h984d5a30c378ee86;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h984d5a30c378ee86;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h038787076a15f5d4;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h00f25f0145e28b8b;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h00f25f0145e28b8b;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'he2ecdac5611d9fc2;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h57fbb9afb302da66;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h57fbb9afb302da66;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hf78576ef8376ac06;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hf78576ef8376ac06;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h304e4d60f7723eee;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'hf78576ef8376ac06;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h14b43729322f7d64;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h304e4d60f7723eee;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h40aaf5813715156e;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h304e4d60f7723eee;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hd57800aa786271f0;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h14b43729322f7d64;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h472e958ebe9bbc7d;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h14b43729322f7d64;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h77ebb1efd4b5e6a9;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h40aaf5813715156e;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h5cd20db925029b4a;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hd57800aa786271f0;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h28c6275132dc4165;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h77ebb1efd4b5e6a9;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hb8ea3a719d12083a;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h77ebb1efd4b5e6a9;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hbeda447d1513dd2a;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h5cd20db925029b4a;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'he4a800c976de6bed;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h28c6275132dc4165;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'he696e8cdeda71cdb;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h28c6275132dc4165;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h5e983dbdd14820a2;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h28c6275132dc4165;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'hbd86f47ba86c5e50;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h28c6275132dc4165;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b1;
       data_out_valid_gold = 1'b1;

       data_in = 64'hae23ce5c7b7b89f6;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hbeda447d1513dd2a;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hddd146bb644605c8;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'he4a800c976de6bed;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'he70f98ce0671030c;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'hbd86f47ba86c5e50;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'hd9b8c0b35ca26fb9;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h9cfc7a39066cf10c;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h271c434e02fbf905;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h46e7538d847fb208;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h46e7538d847fb208;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h7af6abf548590990;
       data_in_valid = 1'b0;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h0000000000000000;
       fifo_empty_gold = 1'b1;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h12a90325a005a640;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h12a90325a005a640;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h94ded82916cbf92d;
       data_in_valid = 1'b0;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h12a90325a005a640;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b1;

       data_in = 64'h2876695060272dc0;
       data_in_valid = 1'b1;
       pop_fifo = 1'b1;
       @(posedge clk);
       data_out_gold = 64'h2876695060272dc0;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       data_in = 64'h7a87aff5faf32ef5;
       data_in_valid = 1'b1;
       pop_fifo = 1'b0;
       @(posedge clk);
       data_out_gold = 64'h2876695060272dc0;
       fifo_empty_gold = 1'b0;
       fifo_full_gold = 1'b0;
       data_out_valid_gold = 1'b0;

       // END OF TEST CASES

       if (fail)
         $display("TEST FAILED");
       else if (partial_fail)
         $display("TEST FAILED WITH MINOR ERRORS");
       else
         $display("TEST PASSED");

       $finish;
    end

  always @ (posedge clk)
    begin
       // Print inputs before they change.
       $display("\nCycle: %4d data_in: %x, data_in_valid: %b, pop_fifo: %b", cycle_count, data_in, data_in_valid, pop_fifo);
       # 10;
       if (data_out_valid_gold == 1'b1) begin
         $display("    data_out: %x, Expected data_out: %x, fifo_empty: %b, Expected fifo_empty: %b, fifo_full: %b, Expected fifo_full: %b",
           data_out, data_out_gold, fifo_empty, fifo_empty_gold, fifo_full, fifo_full_gold);
       end
       else begin
         $display("    (data_out NOT CHECKED in this cycle) fifo_empty: %b, Expected fifo_empty: %b, fifo_full: %b, Expected fifo_full: %b",
           fifo_empty, fifo_empty_gold, fifo_full, fifo_full_gold);
       end
       if (fifo_full !== fifo_full_gold) begin
         $display("MINORCHECK : In cycle %4d - FULL logic : full = %d, expected full = %d", cycle_count, fifo_full, fifo_full_gold);
         partial_fail = 1;
       end
       if (fifo_empty !== fifo_empty_gold) begin
         $display("MINORCHECK : In cycle %4d - EMPTY logic : empty = %d, expected empty = %d", cycle_count, fifo_empty, fifo_empty_gold);
         partial_fail = 1;
       end
       if (data_out !== data_out_gold && data_out_valid_gold === 1'b1)
       begin
         fail = 1;
         err = 1'b1;
         $display("ERRORCHECK : In cycle %4d - Data out error. data_out = %x, expcted data_out = %x", cycle_count, data_out, data_out_gold);
       end
       else
         err = 1'b0;

       cycle_count = cycle_count + 1;
    end

endmodule
