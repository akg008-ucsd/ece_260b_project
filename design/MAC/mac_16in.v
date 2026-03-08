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

output reg [bw_psum-1:0] out;
input  [pr*bw-1:0] a;
input  [pr*bw-1:0] b;
input clk, reset;
`ifdef CLK_GATE
input [pr-1:0] zero;
`endif

/*
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
*/

genvar i,j,k;
/*
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
*/
wire [2*bw-1:0]	product      [pr-1:0]; 

`ifndef MULT_PIPE_EN
reg  [2*bw-1:0]	product_pipe [pr-1:0]; 

generate 
	for(i=0; i<pr; i=i+1) begin : compute_prod
	`ifdef CLK_GATE
	   assign product[i] = zero[i] ? {2*bw{1'b0}} : {{(bw){a[bw*(i+1)-1]}} , a[bw*(i+1)-1:bw*i]} * {{(bw){b[bw*(i+1)-1]}} , b[bw*(i+1)-1:bw*i]}; 
	`else
	   assign product[i] = {{(bw){a[bw*(i+1)-1]}} , a[bw*(i+1)-1:bw*i]} * {{(bw){b[bw*(i+1)-1]}} , b[bw*(i+1)-1:bw*i]}; 
	`endif
	end
endgenerate

generate 
	for(i=0; i<pr; i=i+1) begin : prod_pipeline
	    always @(posedge clk or posedge reset) begin
		if(reset) begin
		   product_pipe[i] <= {(2*bw){1'b0}}; 
		end
		else begin
		   product_pipe[i] <= product[i]; 
		end
	    end
	end
endgenerate

`else

wire [(bw>>1)-1:0]a_lo[pr-1:0];
wire signed [(bw>>1)-1:0]a_hi[pr-1:0];
wire [(bw>>1)-1:0]b_lo[pr-1:0];
wire signed [(bw>>1)-1:0]b_hi[pr-1:0];

reg signed [bw-1:0]pprod_ll[pr-1:0];
reg signed [bw-1:0]pprod_lh[pr-1:0];
reg signed [bw-1:0]pprod_hl[pr-1:0];
reg signed [bw-1:0]pprod_hh[pr-1:0];

reg signed [2*bw-1:0] product_pipe [pr-1:0];


generate
for(i=0; i<pr; i=i+1) begin : split_hi_lo
   assign a_lo[i] = a[(bw*i+(bw>>1))-1:bw*i];
   assign a_hi[i] = a[bw*(i+1)-1:bw*i+(bw>>1)];
   assign b_lo[i] = b[(bw*i+(bw>>1))-1:bw*i];
   assign b_hi[i] = b[bw*(i+1)-1:bw*i+(bw>>1)];
end
endgenerate

generate
	for(j=0; j<pr; j=j+1) begin : stage_1
	   always @(posedge clk or posedge reset) begin
		if(reset) begin
	  	    pprod_ll[j] <= {(bw){1'b0}};
	            pprod_lh[j] <= {(bw){1'b0}};
	            pprod_hl[j] <= {(bw){1'b0}};
	            pprod_hh[j] <= {(bw){1'b0}};
		end
	        else begin
	  	    pprod_ll[j] <= a_lo[j]          * b_lo[j];
	            pprod_lh[j] <= a_lo[j] * $signed({{(bw>>1){b_hi[j][(bw>>1)-1]}}, b_hi[j]});
	            pprod_hl[j] <= $signed({{(bw>>1){a_hi[j][(bw>>1)-1]}}, a_hi[j]}) * b_lo[j];
	            pprod_hh[j] <= $signed(a_hi[j]) * $signed(b_hi[j]);
		end
	   end
	end
endgenerate

wire signed [2*bw-1:0] high_nib [pr-1:0];
wire signed [2*bw-1:0] mid_nib [pr-1:0];
wire signed [2*bw-1:0] low_nib [pr-1:0];

wire signed [2*bw-1:0] w_mid_nib [pr-1:0];
wire mid_nib_sign[pr-1:0];

generate
    for(k=0; k<pr; k=k+1) begin: partial_add
        assign high_nib[k] = pprod_hh[k] << bw;
        assign w_mid_nib[k] = pprod_lh[k] + pprod_hl[k];
	assign mid_nib_sign[k] =  w_mid_nib[k][bw-1];
        assign mid_nib[k]  = {{4{mid_nib_sign[k]}}, w_mid_nib[k], 4'b0000};
        assign low_nib[k] = {{8{1'b0}}, pprod_ll[k]};
    end
endgenerate

generate
	for(k=0; k<pr; k=k+1) begin : stage_2
	   always @(posedge clk or posedge reset) begin
	        if(reset) begin
	  	    product_pipe[k] <= {(2*bw){1'b0}};
	        end
	        else begin
	  	    product_pipe[k] <= high_nib[k] + mid_nib[k] + low_nib[k];
	        end
	   end
	end
endgenerate



`endif

integer p;
always @(*) begin
    out = {(bw_psum){1'b0}};
    for(p=0; p<pr; p=p+1) begin
	out = out + {{4{product_pipe[p][2*bw-1]}}, product_pipe[p]};
    end	
end	

endmodule
