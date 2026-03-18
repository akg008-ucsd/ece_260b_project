/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Wed Mar 18 16:44:25 2026
/////////////////////////////////////////////////////////////


module buffer_1 ( in_clk, out_clk );
  input in_clk;
  output out_clk;

  tri   in_clk;
  assign out_clk = in_clk;

endmodule


module buffer_0 ( in_clk, out_clk );
  input in_clk;
  output out_clk;

  tri   in_clk;
  assign out_clk = in_clk;

endmodule


module fullchip ( clk, reset, inst, core1_mem_in, out, core0_mem_in );
  input [19:0] inst;
  input [63:0] core1_mem_in;
  output [319:0] out;
  input [63:0] core0_mem_in;
  input clk, reset;

  tri   clk;
  tri   reset;
  tri   [19:0] inst;
  tri   [63:0] core1_mem_in;
  tri   [319:0] out;
  tri   [63:0] core0_mem_in;
  tri   core0_clk;
  tri   core1_clk;
  tri   core0_fifo_ext_rd;
  tri   core0_fifo_ext_wr;
  tri   [23:0] core0_sum_in;
  tri   [23:0] core0_sum_out;
  tri   core1_fifo_ext_rd;
  tri   core1_fifo_ext_wr;
  tri   [23:0] core1_sum_in;
  tri   [23:0] core1_sum_out;

  buffer_1 clkbuf_core0 ( .in_clk(clk), .out_clk(core0_clk) );
  buffer_0 clkbuf_core1 ( .in_clk(clk), .out_clk(core1_clk) );
  core core_instance0 ( .reset(reset), .clk(core0_clk), .mem_in(core0_mem_in), 
        .fifo_ext_rd(core0_fifo_ext_rd), .fifo_ext_wr(core0_fifo_ext_wr), 
        .sum_in(core0_sum_in), .sum_out(core0_sum_out), .out(out[319:160]), 
        .inst(inst) );
  core core_instance1 ( .reset(reset), .clk(core1_clk), .mem_in(core1_mem_in), 
        .fifo_ext_rd(core1_fifo_ext_rd), .fifo_ext_wr(core1_fifo_ext_wr), 
        .sum_in(core1_sum_in), .sum_out(core1_sum_out), .out(out[159:0]), 
        .inst(inst) );
  async_fifo async_fifo_core_01 ( .wr_clk(core0_clk), .rd_clk(core1_clk), 
        .reset(reset), .data_in(core0_sum_out), .wr(core0_fifo_ext_wr), .rd(
        core1_fifo_ext_rd), .data_out(core1_sum_in) );
  async_fifo async_fifo_core_10 ( .wr_clk(core1_clk), .rd_clk(core0_clk), 
        .reset(reset), .data_in(core1_sum_out), .wr(core1_fifo_ext_wr), .rd(
        core0_fifo_ext_rd), .data_out(core0_sum_in) );
endmodule

