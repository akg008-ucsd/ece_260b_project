// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`ifdef CLK_GATE
module mac_col (clk, reset, out, q_in, in_zero, out_zero, q_out, i_inst, fifo_wr, o_inst);
`else
module mac_col (clk, reset, out, q_in, q_out, i_inst, fifo_wr, o_inst);
`endif
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter pr = 8;
parameter col_id = 0;
output signed [bw_psum-1:0] out;
input  signed [pr*bw-1:0] q_in;
`ifdef CLK_GATE
input	[pr-1:0] in_zero;
output  [pr-1:0] out_zero;
`endif
output signed [pr*bw-1:0] q_out;
input  clk, reset;
input  [1:0] i_inst; // [1]: execute, [0]: load 
output [1:0] o_inst; // [1]: execute, [0]: load 
output fifo_wr;
/**
Instruction Map:
01: Load
10: Execute 
*/
reg    load_ready_q;
reg    [3:0] cnt_q;
reg    [1:0] inst_q;
reg    [1:0] inst_2q;
reg    [1:0] inst_3q;
`ifdef CLK_GATE
reg	 	[pr-1:0] in_zero_q;
reg	 	[pr-1:0] key_zero_q;
`endif
reg   signed [pr*bw-1:0] query_q;
reg   signed [pr*bw-1:0] key_q;
wire  signed [bw_psum-1:0] psum;
assign o_inst = inst_q;
assign fifo_wr = inst_3q[1] & ~inst_3q[0];
assign out = psum;
assign q_out  = query_q;
`ifdef CLK_GATE
assign out_zero = in_zero_q;
`endif
mac_16in #(.bw(bw), .bw_psum(bw_psum), .pr(pr)) mac_16in_instance (
        .a		(query_q), 
        .b		(key_q),
		`ifdef CLK_GATE
		.zero	(key_zero_q | in_zero_q),
		`endif
        .clk	(clk),
        .reset	(reset),
		.out	(psum)
); 
always @ (posedge clk or posedge reset) begin
  if (reset) begin
    cnt_q 			<= 4'b0;
    load_ready_q 	<= 1'b1;
	key_q 			<= 64'b0;
	query_q 		<= 64'b0;
    inst_q 			<= 2'b0;
    inst_2q 		<= 2'b0;
    inst_3q 		<= 2'b0;
	`ifdef CLK_GATE
	in_zero_q 		<= {pr{1'b0}};
	key_zero_q 		<= {pr{1'b0}};
	`endif
  end
  else begin
    inst_q  <= i_inst;
    inst_2q <= inst_q;
    inst_3q <= inst_2q;
	`ifdef CLK_GATE
	in_zero_q <= in_zero;
	`endif
    if(inst_q[0] && inst_q[1]) begin
        load_ready_q <= 1;
		`ifdef CLK_GATE
		key_zero_q <= {pr{1'b0}};
		in_zero_q  <= {pr{1'b0}};
		`endif
    end
    else if (inst_q[0]) begin
        query_q <= q_in;

       	if (cnt_q == 8-col_id) begin
        	cnt_q        <= 0;
        	load_ready_q <= 0;
	    	if(load_ready_q) begin
                key_q <= q_in;
				`ifdef CLK_GATE
                key_zero_q <= in_zero; 
				`endif
			end
       	end
       	else if (load_ready_q)
         	cnt_q <= cnt_q + 1;
    end
    else if(inst_q[1]) begin
        query_q <= q_in;
    end
  end
end
endmodule
