// Created by prof. Mingu Kang @VVIP Lab, UCSD ECE

module core #(
parameter col = 8,
parameter bw = 8,
parameter bw_psum = 2*bw+4,
parameter bw_psum_sum = bw_psum+4,
parameter pr = 8)
(
    input clk,
    input reset,
    input [pr*bw-1:0] mem_in,
    input [bw_psum_sum-1:0] sum_in,
    input [19:0] inst,
    output fifo_ext_rd,
    output fifo_ext_wr,
    output [bw_psum_sum-1:0] sum_out,
    output [bw_psum*col-1:0] out
);


// Internal wires
wire [pr*bw-1:0] mac_in;
wire [pr*bw-1:0] kmem_out;
wire [pr*bw-1:0] qmem_out;
wire [bw_psum*col-1:0] pmem_in;
wire [bw_psum*col-1:0] pmem_out;
wire [bw_psum*col-1:0] ofifo_out;
wire [bw_psum*col-1:0] sfp_out;
wire [bw_psum*col-1:0] array_out;
wire [col-1:0] ofifo_wr;

// Wires derived from instruction
wire [1:0] mac_inst      = inst[7:6];
wire qmem_rd             = inst[5];
wire qmem_wr             = inst[4];
wire kmem_rd             = inst[3];
wire kmem_wr             = inst[2];
wire pmem_rd             = inst[1];
wire pmem_wr             = inst[0];
wire ofifo_rd            = inst[15];
wire [3:0] kqmem_addr    = inst[14:11];
wire [2:0] pmem_addr     = inst[10:8];
wire sfp_acc             = inst[16];
wire sfp_div             = inst[17];
wire pmem_src_sel        = inst[18];
wire kqmem_src_sel       = inst[19];

// Assign output
assign out = pmem_out;

// Truncate PMEM output for KMEM
genvar i;
wire [pr*bw-1:0] kmem_trunc_in;
generate
    for (i = 0; i<col; i=i+1) begin : loop
        assign kmem_trunc_in[(i*pr+bw)-1 : i*bw] = pmem_out[((7-i)*bw_psum + bw)-1 : (7-i)*bw_psum];
    end    
endgenerate

// MUX inputs
wire [pr*bw-1:0] kmem_in = kqmem_src_sel ? mem_in : kmem_trunc_in;
wire [bw_psum*col-1:0] pmem_mux_in = pmem_src_sel ? ofifo_out : sfp_out;

// MAC input selection
reg mac_in_mux_sel;
always @(posedge clk or posedge reset) begin
    if (reset) mac_in_mux_sel <= 1'b0;
    else mac_in_mux_sel <= mac_inst[0];
end
assign mac_in = mac_in_mux_sel ? kmem_out : qmem_out;

// MAC array
mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
    .in(mac_in),
    .clk(clk),
    .reset(reset),
    .inst(mac_inst),
    .fifo_wr(ofifo_wr),
    .out(array_out)
);

// OFIFO instance
ofifo #(.bw(bw_psum), .col(col)) ofifo_instance (
    .reset(reset),
    .clk(clk),
    .in(array_out),
    .wr(ofifo_wr),
    .rd(ofifo_rd),
    .o_valid(),
    .out(ofifo_out)
);

// QMEM instance
sram_w16 #(.sram_bit(pr*bw)) qmem_instance (
    .CLK(clk),
    .D(mem_in),
    .Q(qmem_out),
    .CEN(!(qmem_rd||qmem_wr)),
    .WEN(!qmem_wr), 
    .A(kqmem_addr)
);

// KMEM instance
sram_w16 #(.sram_bit(pr*bw)) kmem_instance (
    .CLK(clk),
    .D(kmem_in),
    .Q(kmem_out),
    .CEN(!(kmem_rd||kmem_wr)),
    .WEN(!kmem_wr), 
    .A(kqmem_addr)
);

// PMEM instance
sram_w8 #(.sram_bit(col*bw_psum)) psum_mem_instance (
    .CLK(clk),
    .D(pmem_mux_in),
    .Q(pmem_out),
    .CEN(!(pmem_rd||pmem_wr)),
    .WEN(!pmem_wr), 
    .A(pmem_addr)
);

// SFP row
sfp_row #(.bw_psum(bw_psum), .col(col), .bw(bw)) sfp_instance (
    .clk(clk), 
    .reset(reset),
    .div(sfp_div), 
    .acc(sfp_acc), 
    .fifo_ext_rd(fifo_ext_rd), 
    .fifo_ext_wr(fifo_ext_wr), 
    .sum_in(sum_in),
    .sfp_in(pmem_out),
    .sfp_out(sfp_out),
    .sum_out(sum_out)
);

endmodule
