// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sfp_row (clk, reset, acc, div, fifo_ext_rd, fifo_ext_wr, sum_in, sum_out, sfp_in, sfp_out);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4; //Sum of 8 scalar dot products of 16-bits each
  parameter bw_psum_sum = bw_psum+4; //Sum of 8 psums that is sent/received
// Both bw_psum and bw_psum_sum have 1 bit padding to facilitate debugging
 
  input  clk, reset, div, acc;
  input  [bw_psum_sum-1:0] sum_in;     // sum from other Core
  input  [col*bw_psum-1:0] sfp_in; // 8 * 20 -> 8 dot products per Query

  output fifo_ext_rd;
  output fifo_ext_wr;
  output [col*bw_psum-1:0] sfp_out;
  output [bw_psum_sum-1:0] sum_out;

  wire  [col*bw_psum-1:0] abs;     // abs value of each dot product in sfp_in
  `ifdef CLK_GATE
  wire   zero_flag0;
  wire   zero_flag1;
  wire   zero_flag2;
  wire   zero_flag3;
  wire   zero_flag4;
  wire   zero_flag5;
  wire   zero_flag6;
  wire   zero_flag7;
  `endif
  reg    div_q;
  reg    div_2q;
  reg    acc_q; // to store acc input


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

  assign sfp_in_sign0 =  sfp_in[bw_psum*1-1 : bw_psum*0];
  assign sfp_in_sign1 =  sfp_in[bw_psum*2-1 : bw_psum*1];
  assign sfp_in_sign2 =  sfp_in[bw_psum*3-1 : bw_psum*2];
  assign sfp_in_sign3 =  sfp_in[bw_psum*4-1 : bw_psum*3];
  assign sfp_in_sign4 =  sfp_in[bw_psum*5-1 : bw_psum*4];
  assign sfp_in_sign5 =  sfp_in[bw_psum*6-1 : bw_psum*5];
  assign sfp_in_sign6 =  sfp_in[bw_psum*7-1 : bw_psum*6];
  assign sfp_in_sign7 =  sfp_in[bw_psum*8-1 : bw_psum*7];

  `ifdef CLK_GATE
  assign zero_flag0 = (sfp_in[bw_psum*1-1 : bw_psum*0] == 20'b0);
  assign zero_flag1 = (sfp_in[bw_psum*2-1 : bw_psum*1] == 20'b0);
  assign zero_flag2 = (sfp_in[bw_psum*3-1 : bw_psum*2] == 20'b0);
  assign zero_flag3 = (sfp_in[bw_psum*4-1 : bw_psum*3] == 20'b0);
  assign zero_flag4 = (sfp_in[bw_psum*5-1 : bw_psum*4] == 20'b0);
  assign zero_flag5 = (sfp_in[bw_psum*6-1 : bw_psum*5] == 20'b0);
  assign zero_flag6 = (sfp_in[bw_psum*7-1 : bw_psum*6] == 20'b0);
  assign zero_flag7 = (sfp_in[bw_psum*8-1 : bw_psum*7] == 20'b0);

  assign sfp_out[bw_psum*1-1 : bw_psum*0] = (!zero_flag0) ? sfp_out_sign0 : 20'b0;
  assign sfp_out[bw_psum*2-1 : bw_psum*1] = (!zero_flag1) ? sfp_out_sign1 : 20'b0;
  assign sfp_out[bw_psum*3-1 : bw_psum*2] = (!zero_flag2) ? sfp_out_sign2 : 20'b0;
  assign sfp_out[bw_psum*4-1 : bw_psum*3] = (!zero_flag3) ? sfp_out_sign3 : 20'b0;
  assign sfp_out[bw_psum*5-1 : bw_psum*4] = (!zero_flag4) ? sfp_out_sign4 : 20'b0;
  assign sfp_out[bw_psum*6-1 : bw_psum*5] = (!zero_flag5) ? sfp_out_sign5 : 20'b0;
  assign sfp_out[bw_psum*7-1 : bw_psum*6] = (!zero_flag6) ? sfp_out_sign6 : 20'b0;
  assign sfp_out[bw_psum*8-1 : bw_psum*7] = (!zero_flag7) ? sfp_out_sign7 : 20'b0;

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

  assign sum_2core = sum_this_core[bw_psum_sum-1:7] + sum_in[bw_psum_sum-1:7]; // Right shift denominator by 7 bits

  assign abs[bw_psum*1-1 : bw_psum*0] = (sfp_in[bw_psum*1-1]) ?  (~sfp_in[bw_psum*1-1 : bw_psum*0] + 1)  :  sfp_in[bw_psum*1-1 : bw_psum*0];
  assign abs[bw_psum*2-1 : bw_psum*1] = (sfp_in[bw_psum*2-1]) ?  (~sfp_in[bw_psum*2-1 : bw_psum*1] + 1)  :  sfp_in[bw_psum*2-1 : bw_psum*1];
  assign abs[bw_psum*3-1 : bw_psum*2] = (sfp_in[bw_psum*3-1]) ?  (~sfp_in[bw_psum*3-1 : bw_psum*2] + 1)  :  sfp_in[bw_psum*3-1 : bw_psum*2];
  assign abs[bw_psum*4-1 : bw_psum*3] = (sfp_in[bw_psum*4-1]) ?  (~sfp_in[bw_psum*4-1 : bw_psum*3] + 1)  :  sfp_in[bw_psum*4-1 : bw_psum*3];
  assign abs[bw_psum*5-1 : bw_psum*4] = (sfp_in[bw_psum*5-1]) ?  (~sfp_in[bw_psum*5-1 : bw_psum*4] + 1)  :  sfp_in[bw_psum*5-1 : bw_psum*4];
  assign abs[bw_psum*6-1 : bw_psum*5] = (sfp_in[bw_psum*6-1]) ?  (~sfp_in[bw_psum*6-1 : bw_psum*5] + 1)  :  sfp_in[bw_psum*6-1 : bw_psum*5];
  assign abs[bw_psum*7-1 : bw_psum*6] = (sfp_in[bw_psum*7-1]) ?  (~sfp_in[bw_psum*7-1 : bw_psum*6] + 1)  :  sfp_in[bw_psum*7-1 : bw_psum*6];
  assign abs[bw_psum*8-1 : bw_psum*7] = (sfp_in[bw_psum*8-1]) ?  (~sfp_in[bw_psum*8-1 : bw_psum*7] + 1)  :  sfp_in[bw_psum*8-1 : bw_psum*7];

  assign fifo_ext_wr = fifo_wr;
  assign fifo_ext_rd = div_q;
  assign sum_out	 = sum_q;

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
      div_q <= 0;
      div_2q <= 0;
      acc_q <= 0;
      fifo_wr <= 0;
      sfp_out_sign0 <= 20'b0;
      sfp_out_sign1 <= 20'b0;
      sfp_out_sign2 <= 20'b0;
      sfp_out_sign3 <= 20'b0;
      sfp_out_sign4 <= 20'b0;
      sfp_out_sign5 <= 20'b0;
      sfp_out_sign6 <= 20'b0;
      sfp_out_sign7 <= 20'b0;
	  sum_q <= 24'b0;
    end
    else begin
		div_q <= div;
		div_2q <= div_q;
       	acc_q <= acc;
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
           {4'b0, abs[bw_psum*8-1 : bw_psum*7]} ;

       end
       else begin
         if (div_2q) begin
           /*
           sfp_out_sign0 <= sfp_in_sign0 / sum_2core;
           sfp_out_sign1 <= sfp_in_sign1 / sum_2core;
           sfp_out_sign2 <= sfp_in_sign2 / sum_2core;
           sfp_out_sign3 <= sfp_in_sign3 / sum_2core;
           sfp_out_sign4 <= sfp_in_sign4 / sum_2core;
           sfp_out_sign5 <= sfp_in_sign5 / sum_2core;
           sfp_out_sign6 <= sfp_in_sign6 / sum_2core;
           sfp_out_sign7 <= sfp_in_sign7 / sum_2core; */

           // Division operation (eg. for Q1) abs(Ki*Q1) / sum(Ki*Qi)
           `ifdef CLK_GATE
           if (!zero_flag0)
             sfp_out_sign0 <= abs[bw_psum*1-1 : bw_psum*0] / sum_2core;
           if (!zero_flag1)
             sfp_out_sign1 <= abs[bw_psum*2-1 : bw_psum*1] / sum_2core;
           if (!zero_flag2)
             sfp_out_sign2 <= abs[bw_psum*3-1 : bw_psum*2] / sum_2core;
           if (!zero_flag3)
             sfp_out_sign3 <= abs[bw_psum*4-1 : bw_psum*3] / sum_2core;
           if (!zero_flag4)
             sfp_out_sign4 <= abs[bw_psum*5-1 : bw_psum*4] / sum_2core;
           if (!zero_flag5)
             sfp_out_sign5 <= abs[bw_psum*6-1 : bw_psum*5] / sum_2core;
           if (!zero_flag6)
             sfp_out_sign6 <= abs[bw_psum*7-1 : bw_psum*6] / sum_2core;
           if (!zero_flag7)
             sfp_out_sign7 <= abs[bw_psum*8-1 : bw_psum*7] / sum_2core;
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

         end
       end
   end
 end


endmodule

