// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`ifdef CLK_GATE
module mac_16in (out, a, b, zero, clk, reset);
`else
module mac_16in (out, a, b, clk, reset);
`endif

parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter pr = 8; // parallel factor: number of inputs = 8

output [bw_psum-1:0] out;
input  [pr*bw-1:0] a;
input  [pr*bw-1:0] b;
input clk, reset;
`ifdef CLK_GATE
input [pr-1:0] zero;
`endif

wire		[2*bw-1:0]	product0	;
wire		[2*bw-1:0]	product1	;
wire		[2*bw-1:0]	product2	;
wire		[2*bw-1:0]	product3	;
wire		[2*bw-1:0]	product4	;
wire		[2*bw-1:0]	product5	;
wire		[2*bw-1:0]	product6	;
wire		[2*bw-1:0]	product7	;

reg		[2*bw-1:0]	product_pipe_q0	;
reg		[2*bw-1:0]	product_pipe_q1	;
reg		[2*bw-1:0]	product_pipe_q2	;
reg		[2*bw-1:0]	product_pipe_q3	;
reg		[2*bw-1:0]	product_pipe_q4	;
reg		[2*bw-1:0]	product_pipe_q5	;
reg		[2*bw-1:0]	product_pipe_q6	;
reg		[2*bw-1:0]	product_pipe_q7	;


genvar i;

`ifdef CLK_GATE
assign	product0	=	zero[0] ? {2*bw{1'b0}} : {{(bw){a[bw*1-1]}} , a[bw*1-1:bw*0]} * {{(bw){b[bw*1-1]}} , b[bw*1-1:bw*0]};
assign	product1	=	zero[1] ? {2*bw{1'b0}} : {{(bw){a[bw*2-1]}} , a[bw*2-1:bw*1]} * {{(bw){b[bw*2-1]}} , b[bw*2-1:bw*1]};
assign	product2	=	zero[2] ? {2*bw{1'b0}} : {{(bw){a[bw*3-1]}} , a[bw*3-1:bw*2]} * {{(bw){b[bw*3-1]}} , b[bw*3-1:bw*2]};
assign	product3	=	zero[3] ? {2*bw{1'b0}} : {{(bw){a[bw*4-1]}} , a[bw*4-1:bw*3]} * {{(bw){b[bw*4-1]}} , b[bw*4-1:bw*3]};
assign	product4	=	zero[4] ? {2*bw{1'b0}} : {{(bw){a[bw*5-1]}} , a[bw*5-1:bw*4]} * {{(bw){b[bw*5-1]}} , b[bw*5-1:bw*4]};
assign	product5	=	zero[5] ? {2*bw{1'b0}} : {{(bw){a[bw*6-1]}} , a[bw*6-1:bw*5]} * {{(bw){b[bw*6-1]}} , b[bw*6-1:bw*5]};
assign	product6	=	zero[6] ? {2*bw{1'b0}} : {{(bw){a[bw*7-1]}} , a[bw*7-1:bw*6]} * {{(bw){b[bw*7-1]}} , b[bw*7-1:bw*6]};
assign	product7	=	zero[7] ? {2*bw{1'b0}} : {{(bw){a[bw*8-1]}} , a[bw*8-1:bw*7]} * {{(bw){b[bw*8-1]}} , b[bw*8-1:bw*7]};
`else
assign	product0	=	{{(bw){a[bw*1-1]}} , a[bw*1-1:bw*0]} * {{(bw){b[bw*1-1]}} , b[bw*1-1:bw*0]};
assign	product1	=	{{(bw){a[bw*2-1]}} , a[bw*2-1:bw*1]} * {{(bw){b[bw*2-1]}} , b[bw*2-1:bw*1]};
assign	product2	=	{{(bw){a[bw*3-1]}} , a[bw*3-1:bw*2]} * {{(bw){b[bw*3-1]}} , b[bw*3-1:bw*2]};
assign	product3	=	{{(bw){a[bw*4-1]}} , a[bw*4-1:bw*3]} * {{(bw){b[bw*4-1]}} , b[bw*4-1:bw*3]};
assign	product4	=	{{(bw){a[bw*5-1]}} , a[bw*5-1:bw*4]} * {{(bw){b[bw*5-1]}} , b[bw*5-1:bw*4]};
assign	product5	=	{{(bw){a[bw*6-1]}} , a[bw*6-1:bw*5]} * {{(bw){b[bw*6-1]}} , b[bw*6-1:bw*5]};
assign	product6	=	{{(bw){a[bw*7-1]}} , a[bw*7-1:bw*6]} * {{(bw){b[bw*7-1]}} , b[bw*7-1:bw*6]};
assign	product7	=	{{(bw){a[bw*8-1]}} , a[bw*8-1:bw*7]} * {{(bw){b[bw*8-1]}} , b[bw*8-1:bw*7]};
`endif

assign out = 
                {{(4){product_pipe_q0[2*bw-1]}},product_pipe_q0	}
	+	{{(4){product_pipe_q1[2*bw-1]}},product_pipe_q1	}
	+	{{(4){product_pipe_q2[2*bw-1]}},product_pipe_q2	}
	+	{{(4){product_pipe_q3[2*bw-1]}},product_pipe_q3	}
	+	{{(4){product_pipe_q4[2*bw-1]}},product_pipe_q4	}
	+	{{(4){product_pipe_q5[2*bw-1]}},product_pipe_q5	}
	+	{{(4){product_pipe_q6[2*bw-1]}},product_pipe_q6	}
	+	{{(4){product_pipe_q7[2*bw-1]}},product_pipe_q7	};

always @(posedge clk or posedge reset) begin
	if(reset) begin
		product_pipe_q0 <= 16'b0;
		product_pipe_q1 <= 16'b0;
		product_pipe_q2 <= 16'b0;
		product_pipe_q3 <= 16'b0;
		product_pipe_q4 <= 16'b0;
		product_pipe_q5 <= 16'b0;
		product_pipe_q6 <= 16'b0;
		product_pipe_q7 <= 16'b0;
	end
	else begin
		product_pipe_q0 <= product0;
		product_pipe_q1 <= product1;
		product_pipe_q2 <= product2;
		product_pipe_q3 <= product3;
		product_pipe_q4 <= product4;
		product_pipe_q5 <= product5;
		product_pipe_q6 <= product6;
		product_pipe_q7 <= product7;
	end
end


//wire [bw>>1-1:0]a_lo[pr-1:0]; 
//wire [bw>>1-1:0]a_hi[pr-1:0]; 
//wire [bw>>1-1:0]b_lo[pr-1:0]; 
//wire [bw>>1-1:0]b_hi[pr-1:0];
//
//genvar i;
//generate 
//	for(i=0; i<pr; i=i+1) begin : split_hi_lo
//	    assign a_lo[i] = a[(bw*i+bw>>1)-1:bw*i];
//	    assign a_hi[i] = a[bw*(i+1)-1:bw*i+bw>>1];
//	    assign b_lo[i] = b[(bw*i+bw>>1)-1:bw*i];
//	    assign b_hi[i] = b[bw*(i+1)-1:bw*i+bw>>1];
//	end
//endgenerate
//
//generate 
//	for(i=0; i<pr; i=i+1) begin : stage_1
//	    always @(posedge clk or posedge reset) begin
//		if(reset) begin
//		   pprod_ll <= {(bw){1'b0}};
//		   pprod_lh <= {(bw){1'b0}};
//		   pprod_hl <= {(bw){1'b0}};
//		   pprod_hh <= {(bw){1'b0}};
//		end
//		else begin
//		   pprod_ll <= a_lo[i] * b_lo[i];
//		   pprod_lh <= a_lo[i] * b_hi[i];
//		   pprod_hl <= a_hi[i] * b_lo[i];
//		   pprod_hh <= a_hi[i] * b_hi[i];
//		end
//	    end
//	end
//endgenerate 

endmodule
