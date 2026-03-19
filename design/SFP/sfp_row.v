// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
// SPARSITY_AWARE extension:
//   When defined, after each ACC phase Si = sum_q = sum_j|Qi*Kj| is compared
//   against a programmable threshold. If Si < threshold:
//     GATE: sfp_out_sign register writes suppressed during DIV phase
//           -> sfp_out stays zero, switching activity reduced (power saving)
//     SKIP: sparse_row output exposed so external controller can skip
//           asserting sfp_div entirely for sparse rows (cycle saving)
//   sparse_row is registered one cycle after acc_q falls (same cycle
//   fifo_wr rises), when sum_q holds the final Si value. It is stable
//   well before the controller asserts sfp_div.
//
// FIX (fifo_ext_wr gating in SPARSITY_AWARE mode):
//   When a row is sparse (sparse_row=1) the controller skips sfp_div, so
//   the inter-core async FIFO is never read for that row.  Without gating,
//   the acc phase still writes sum_q into the inter-core FIFO, leaving an
//   unread entry.  In 6B_SA (all rows sparse, sfp_div skipped) this fills
//   the FIFO with 8 stale entries that then corrupt 6C_SA's normalization.
//   Fix: suppress fifo_ext_wr when sparse_row=1 so that sparse rows never
//   write to the inter-core FIFO.  Non-SPARSITY_AWARE behaviour unchanged.
module sfp_row (clk, reset, acc, div, fifo_ext_rd, fifo_ext_wr, sum_in, sum_out, sfp_in, sfp_out
  `ifdef SPARSITY_AWARE
  , threshold, sparse_row
  `endif
  );
 
  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter bw_psum_sum = bw_psum+4;
 
  input  clk, reset, div, acc;
  input  [bw_psum_sum-1:0] sum_in;
  input  [col*bw_psum-1:0] sfp_in;
 
  output fifo_ext_rd;
  output fifo_ext_wr;
  output [col*bw_psum-1:0] sfp_out;
  output [bw_psum_sum-1:0] sum_out;
 
  `ifdef SPARSITY_AWARE
  input  [bw_psum_sum-1:0] threshold;
  output reg               sparse_row;
  `endif
 
  wire  [col*bw_psum-1:0] abs;
 
  `ifdef CLK_GATE
  wire   zero_flag0, zero_flag1, zero_flag2, zero_flag3;
  wire   zero_flag4, zero_flag5, zero_flag6, zero_flag7;
  `endif
 
  reg    div_q;
  reg    div_2q;
  reg    acc_q;
 
  wire [bw_psum_sum-1:0] sum_this_core;
  wire signed [bw_psum-1:0] sum_2core;
 
  wire signed [bw_psum-1:0] sfp_in_sign0;
  wire signed [bw_psum-1:0] sfp_in_sign1;
  wire signed [bw_psum-1:0] sfp_in_sign2;
  wire signed [bw_psum-1:0] sfp_in_sign3;
  wire signed [bw_psum-1:0] sfp_in_sign4;
  wire signed [bw_psum-1:0] sfp_in_sign5;
  wire signed [bw_psum-1:0] sfp_in_sign6;
  wire signed [bw_psum-1:0] sfp_in_sign7;
 
  reg signed [bw_psum-1:0] sfp_out_sign0;
  reg signed [bw_psum-1:0] sfp_out_sign1;
  reg signed [bw_psum-1:0] sfp_out_sign2;
  reg signed [bw_psum-1:0] sfp_out_sign3;
  reg signed [bw_psum-1:0] sfp_out_sign4;
  reg signed [bw_psum-1:0] sfp_out_sign5;
  reg signed [bw_psum-1:0] sfp_out_sign6;
  reg signed [bw_psum-1:0] sfp_out_sign7;
 
  reg [bw_psum_sum-1:0] sum_q;
  reg fifo_wr;
 
  assign sfp_in_sign0 = sfp_in[bw_psum*1-1 : bw_psum*0];
  assign sfp_in_sign1 = sfp_in[bw_psum*2-1 : bw_psum*1];
  assign sfp_in_sign2 = sfp_in[bw_psum*3-1 : bw_psum*2];
  assign sfp_in_sign3 = sfp_in[bw_psum*4-1 : bw_psum*3];
  assign sfp_in_sign4 = sfp_in[bw_psum*5-1 : bw_psum*4];
  assign sfp_in_sign5 = sfp_in[bw_psum*6-1 : bw_psum*5];
  assign sfp_in_sign6 = sfp_in[bw_psum*7-1 : bw_psum*6];
  assign sfp_in_sign7 = sfp_in[bw_psum*8-1 : bw_psum*7];
 
  `ifdef CLK_GATE
  assign zero_flag0 = (sfp_in[bw_psum*1-1 : bw_psum*0] == 20'b0);
  assign zero_flag1 = (sfp_in[bw_psum*2-1 : bw_psum*1] == 20'b0);
  assign zero_flag2 = (sfp_in[bw_psum*3-1 : bw_psum*2] == 20'b0);
  assign zero_flag3 = (sfp_in[bw_psum*4-1 : bw_psum*3] == 20'b0);
  assign zero_flag4 = (sfp_in[bw_psum*5-1 : bw_psum*4] == 20'b0);
  assign zero_flag5 = (sfp_in[bw_psum*6-1 : bw_psum*5] == 20'b0);
  assign zero_flag6 = (sfp_in[bw_psum*7-1 : bw_psum*6] == 20'b0);
  assign zero_flag7 = (sfp_in[bw_psum*8-1 : bw_psum*7] == 20'b0);
 
  `ifdef SPARSITY_AWARE
  assign sfp_out[bw_psum*1-1 : bw_psum*0] = (!zero_flag0 && !sparse_row) ? sfp_out_sign0 : 20'b0;
  assign sfp_out[bw_psum*2-1 : bw_psum*1] = (!zero_flag1 && !sparse_row) ? sfp_out_sign1 : 20'b0;
  assign sfp_out[bw_psum*3-1 : bw_psum*2] = (!zero_flag2 && !sparse_row) ? sfp_out_sign2 : 20'b0;
  assign sfp_out[bw_psum*4-1 : bw_psum*3] = (!zero_flag3 && !sparse_row) ? sfp_out_sign3 : 20'b0;
  assign sfp_out[bw_psum*5-1 : bw_psum*4] = (!zero_flag4 && !sparse_row) ? sfp_out_sign4 : 20'b0;
  assign sfp_out[bw_psum*6-1 : bw_psum*5] = (!zero_flag5 && !sparse_row) ? sfp_out_sign5 : 20'b0;
  assign sfp_out[bw_psum*7-1 : bw_psum*6] = (!zero_flag6 && !sparse_row) ? sfp_out_sign6 : 20'b0;
  assign sfp_out[bw_psum*8-1 : bw_psum*7] = (!zero_flag7 && !sparse_row) ? sfp_out_sign7 : 20'b0;
  `else
  assign sfp_out[bw_psum*1-1 : bw_psum*0] = (!zero_flag0) ? sfp_out_sign0 : 20'b0;
  assign sfp_out[bw_psum*2-1 : bw_psum*1] = (!zero_flag1) ? sfp_out_sign1 : 20'b0;
  assign sfp_out[bw_psum*3-1 : bw_psum*2] = (!zero_flag2) ? sfp_out_sign2 : 20'b0;
  assign sfp_out[bw_psum*4-1 : bw_psum*3] = (!zero_flag3) ? sfp_out_sign3 : 20'b0;
  assign sfp_out[bw_psum*5-1 : bw_psum*4] = (!zero_flag4) ? sfp_out_sign4 : 20'b0;
  assign sfp_out[bw_psum*6-1 : bw_psum*5] = (!zero_flag5) ? sfp_out_sign5 : 20'b0;
  assign sfp_out[bw_psum*7-1 : bw_psum*6] = (!zero_flag6) ? sfp_out_sign6 : 20'b0;
  assign sfp_out[bw_psum*8-1 : bw_psum*7] = (!zero_flag7) ? sfp_out_sign7 : 20'b0;
  `endif
 
  `else
 
  `ifdef SPARSITY_AWARE
  assign sfp_out[bw_psum*1-1 : bw_psum*0] = sparse_row ? 20'b0 : sfp_out_sign0;
  assign sfp_out[bw_psum*2-1 : bw_psum*1] = sparse_row ? 20'b0 : sfp_out_sign1;
  assign sfp_out[bw_psum*3-1 : bw_psum*2] = sparse_row ? 20'b0 : sfp_out_sign2;
  assign sfp_out[bw_psum*4-1 : bw_psum*3] = sparse_row ? 20'b0 : sfp_out_sign3;
  assign sfp_out[bw_psum*5-1 : bw_psum*4] = sparse_row ? 20'b0 : sfp_out_sign4;
  assign sfp_out[bw_psum*6-1 : bw_psum*5] = sparse_row ? 20'b0 : sfp_out_sign5;
  assign sfp_out[bw_psum*7-1 : bw_psum*6] = sparse_row ? 20'b0 : sfp_out_sign6;
  assign sfp_out[bw_psum*8-1 : bw_psum*7] = sparse_row ? 20'b0 : sfp_out_sign7;
  `else
  assign sfp_out[bw_psum*1-1 : bw_psum*0] = sfp_out_sign0;
  assign sfp_out[bw_psum*2-1 : bw_psum*1] = sfp_out_sign1;
  assign sfp_out[bw_psum*3-1 : bw_psum*2] = sfp_out_sign2;
  assign sfp_out[bw_psum*4-1 : bw_psum*3] = sfp_out_sign3;
  assign sfp_out[bw_psum*5-1 : bw_psum*4] = sfp_out_sign4;
  assign sfp_out[bw_psum*6-1 : bw_psum*5] = sfp_out_sign5;
  assign sfp_out[bw_psum*7-1 : bw_psum*6] = sfp_out_sign6;
  assign sfp_out[bw_psum*8-1 : bw_psum*7] = sfp_out_sign7;
  `endif
 
  `endif
 
  assign sum_2core = sum_this_core[bw_psum_sum-1:7] + sum_in[bw_psum_sum-1:7];
 
  assign abs[bw_psum*1-1 : bw_psum*0] = (sfp_in[bw_psum*1-1]) ? (~sfp_in[bw_psum*1-1 : bw_psum*0] + 1) : sfp_in[bw_psum*1-1 : bw_psum*0];
  assign abs[bw_psum*2-1 : bw_psum*1] = (sfp_in[bw_psum*2-1]) ? (~sfp_in[bw_psum*2-1 : bw_psum*1] + 1) : sfp_in[bw_psum*2-1 : bw_psum*1];
  assign abs[bw_psum*3-1 : bw_psum*2] = (sfp_in[bw_psum*3-1]) ? (~sfp_in[bw_psum*3-1 : bw_psum*2] + 1) : sfp_in[bw_psum*3-1 : bw_psum*2];
  assign abs[bw_psum*4-1 : bw_psum*3] = (sfp_in[bw_psum*4-1]) ? (~sfp_in[bw_psum*4-1 : bw_psum*3] + 1) : sfp_in[bw_psum*4-1 : bw_psum*3];
  assign abs[bw_psum*5-1 : bw_psum*4] = (sfp_in[bw_psum*5-1]) ? (~sfp_in[bw_psum*5-1 : bw_psum*4] + 1) : sfp_in[bw_psum*5-1 : bw_psum*4];
  assign abs[bw_psum*6-1 : bw_psum*5] = (sfp_in[bw_psum*6-1]) ? (~sfp_in[bw_psum*6-1 : bw_psum*5] + 1) : sfp_in[bw_psum*6-1 : bw_psum*5];
  assign abs[bw_psum*7-1 : bw_psum*6] = (sfp_in[bw_psum*7-1]) ? (~sfp_in[bw_psum*7-1 : bw_psum*6] + 1) : sfp_in[bw_psum*7-1 : bw_psum*6];
  assign abs[bw_psum*8-1 : bw_psum*7] = (sfp_in[bw_psum*8-1]) ? (~sfp_in[bw_psum*8-1 : bw_psum*7] + 1) : sfp_in[bw_psum*8-1 : bw_psum*7];
 
  // fifo_ext_wr: in SPARSITY_AWARE mode, suppress the inter-core FIFO write
  // when the row is sparse (sparse_row=1).  The controller will skip sfp_div
  // for sparse rows, so no read will occur; without this gate the unread write
  // accumulates in the FIFO and corrupts subsequent dense-row normalization.
  `ifdef SPARSITY_AWARE
  assign fifo_ext_wr = fifo_wr && !sparse_row;
  `else
  assign fifo_ext_wr = fifo_wr;
  `endif
 
  assign fifo_ext_rd = div_q;
  assign sum_out     = sum_q;
 
  fifo_depth16 #(.bw(bw_psum_sum)) fifo_inst_int (
     .rd_clk(clk),
     .wr_clk(clk),
     .in(sum_q),
     .out(sum_this_core),
     .rd(div_q),
     .wr(fifo_wr),
     .reset(reset)
  );
 
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      div_q   <= 0;
      div_2q  <= 0;
      acc_q   <= 0;
      fifo_wr <= 0;
      sum_q   <= 24'b0;
      `ifdef SPARSITY_AWARE
      sparse_row <= 1'b0;
      `endif
      sfp_out_sign0 <= 20'b0;
      sfp_out_sign1 <= 20'b0;
      sfp_out_sign2 <= 20'b0;
      sfp_out_sign3 <= 20'b0;
      sfp_out_sign4 <= 20'b0;
      sfp_out_sign5 <= 20'b0;
      sfp_out_sign6 <= 20'b0;
      sfp_out_sign7 <= 20'b0;
    end
    else begin
      div_q   <= div;
      div_2q  <= div_q;
      acc_q   <= acc;
      fifo_wr <= acc_q;
      if (acc_q) begin
        sum_q <=
          {4'b0, abs[bw_psum*1-1 : bw_psum*0]} +
          {4'b0, abs[bw_psum*2-1 : bw_psum*1]} +
          {4'b0, abs[bw_psum*3-1 : bw_psum*2]} +
          {4'b0, abs[bw_psum*4-1 : bw_psum*3]} +
          {4'b0, abs[bw_psum*5-1 : bw_psum*4]} +
          {4'b0, abs[bw_psum*6-1 : bw_psum*5]} +
          {4'b0, abs[bw_psum*7-1 : bw_psum*6]} +
          {4'b0, abs[bw_psum*8-1 : bw_psum*7]};
      end
      else begin
        // SPARSITY_AWARE: latch sparsity decision when fifo_wr pulses.
        // sum_q is the finalized Si value at this point.
        `ifdef SPARSITY_AWARE
        if (fifo_wr == 1'b1)
          sparse_row <= (sum_q < threshold);
        `endif
 
        if (div_2q) begin
          `ifdef SPARSITY_AWARE
          if (!sparse_row) begin
          `endif
            `ifdef CLK_GATE
            if (!zero_flag0) sfp_out_sign0 <= abs[bw_psum*1-1 : bw_psum*0] / sum_2core;
            if (!zero_flag1) sfp_out_sign1 <= abs[bw_psum*2-1 : bw_psum*1] / sum_2core;
            if (!zero_flag2) sfp_out_sign2 <= abs[bw_psum*3-1 : bw_psum*2] / sum_2core;
            if (!zero_flag3) sfp_out_sign3 <= abs[bw_psum*4-1 : bw_psum*3] / sum_2core;
            if (!zero_flag4) sfp_out_sign4 <= abs[bw_psum*5-1 : bw_psum*4] / sum_2core;
            if (!zero_flag5) sfp_out_sign5 <= abs[bw_psum*6-1 : bw_psum*5] / sum_2core;
            if (!zero_flag6) sfp_out_sign6 <= abs[bw_psum*7-1 : bw_psum*6] / sum_2core;
            if (!zero_flag7) sfp_out_sign7 <= abs[bw_psum*8-1 : bw_psum*7] / sum_2core;
            `else
            sfp_out_sign0 <= abs[bw_psum*1-1 : bw_psum*0] / sum_2core;
            sfp_out_sign1 <= abs[bw_psum*2-1 : bw_psum*1] / sum_2core;
            sfp_out_sign2 <= abs[bw_psum*3-1 : bw_psum*2] / sum_2core;
            sfp_out_sign3 <= abs[bw_psum*4-1 : bw_psum*3] / sum_2core;
            sfp_out_sign4 <= abs[bw_psum*5-1 : bw_psum*4] / sum_2core;
            sfp_out_sign5 <= abs[bw_psum*6-1 : bw_psum*5] / sum_2core;
            sfp_out_sign6 <= abs[bw_psum*7-1 : bw_psum*6] / sum_2core;
            sfp_out_sign7 <= abs[bw_psum*8-1 : bw_psum*7] / sum_2core;
            `endif
          `ifdef SPARSITY_AWARE
          end
          `endif
        end
      end
    end
  end
 
endmodule
