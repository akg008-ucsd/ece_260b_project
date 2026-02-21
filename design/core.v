module core (clk, fifo_ext_rd, fifo_ext_wr, sum_in, sum_out, mem_in, out, inst, reset);
    input clk;
    input fifo_ext_rd;
    input fifo_ext_wr;
    input [bw_psum_sum-1:0] sum_in;
    output [bw_psum_sum-1:0] sum_out;
    input [pr*bw-1:0] mem_in;
    output [bw_psum*col-1:0] out;
    input [19:0] inst;
    input reset;
endmodule


parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter bw_psum_sum = bw_psum+4;
parameter pr = 8;

output fifo_ext_rd;
output fifo_ext_wr;
input [bw_psum_sum-1:0] sum_in;
output [bw_psum_sum-1:0] sum_out;
output [bw_psum*col-1:0] out;
wire [bw_psum*col-1:0] pmem_out;
input [pr*bw-1:0] mem_in;
input clk;
input reset;

input [19:0] inst; // Core instruction input

// Wire Bunch0 (Not derived from inst)
wire [pr*bw-1:0] mac_in;
wire [pr*bw-1:0] kmem_out;
wire [pr*bw-1:0] qmem_out;
wire [bw_psum*col-1:0] pmem_in;
wire [bw_psum*col-1:0] ofifo_out;
wire [bw_psum*col-1:0] sfp_out;
wire [bw_psum*col-1:0] array_out;
wire [col-1:0] ofifo_wr;
wire [pr*bw-1:0] kmem_in;
wire [pr*bw-1:0] kmem_trunc_in;
wire [3:0] kqmem_addr_cu;
wire ofifo_valid;

// Wire Bunch1 (Derived from inst[7:0])
wire [1:0] mac_inst;
wire qmem_rd;
wire qmem_wr;
wire kmem_rd;
wire kmem_wr;
wire pmem_rd;
wire pmem_wr;

// Wire Bunch2 (Derived from inst[16:8])
wire ofifo_rd;
wire [3:0] kqmem_addr;
wire [2:0] pmem_addr;

// Wire Bunch3 (Derived from inst[20:17])
wire sfp_acc;
wire sfp_div;
wire pmem_src_sel;
wire kqmem_src_sel;

// Non-truncated PMEM_OUT is connected to OUT
assign out = pmem_out;

// Generate truncated KMEM_IN from non-truncated PMEM_OUT
genvar i;
generate
    for (i = 0; i < col; i = i + 1) begin : loop
        assign kmem_trunc_in[(i*pr+bw)-1 : i*bw] = pmem_out[((7-i)*(bw_psum) + bw)-1 :(7-i)*(bw_psum)];
    end    
endgenerate

// MUXES for input of KMEM and PMEM
assign kmem_in = kqmem_src_sel ? mem_in : kmem_trunc_in;
assign pmem_in = pmem_src_sel ? ofifo_out : sfp_out;

// Control Unit logic is NOT used because CU_EN is not defined
assign kqmem_src_sel = inst[19];
assign pmem_src_sel  = inst[18];
assign sfp_div       = inst[17];
assign sfp_acc       = inst[16];

assign ofifo_rd      = inst[15];
assign kqmem_addr    = inst[14:11];
assign pmem_addr     = inst[10:8];

assign mac_inst      = inst[7:6];
assign qmem_rd       = inst[5];
assign qmem_wr       = inst[4];
assign kmem_rd       = inst[3];
assign kmem_wr       = inst[2];
assign pmem_rd       = inst[1];
assign pmem_wr       = inst[0];

// MAC input selection logic
reg mac_in_mux_sel;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mac_in_mux_sel <= 1'b0;
    end else begin
        mac_in_mux_sel <= mac_inst[0];
    end
end

assign mac_in = mac_in_mux_sel ? kmem_out : qmem_out;

// Core instantiation without CU_EN logic
core core_instance0 (
    .clk(clk),
    .fifo_ext_rd(fifo_ext_rd),
    .fifo_ext_wr(fifo_ext_wr),
    .sum_in(sum_in),
    .sum_out(sum_out),
    .mem_in(mem_in),
    .out(pmem_out),
    .inst(inst),
    .reset(reset)
);

// Muxed inputs for MAC Array instance
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
    .o_valid(ofifo_valid),
    .out(ofifo_out)
);

// SRAM instances for QMEM, KMEM, and PMEM
sram_w16 #(.sram_bit(pr*bw)) qmem_instance (
    .CLK(clk),
    .D(mem_in),
    .Q(qmem_out),
    .CEN(!(qmem_rd || qmem_wr)),
    .WEN(!qmem_wr), 
    .A(kqmem_addr)
);

sram_w16 #(.sram_bit(pr*bw)) kmem_instance (
    .CLK(clk),
    .D(kmem_in),
    .Q(kmem_out),
    .CEN(!(kmem_rd || kmem_wr)),
    .WEN(!kmem_wr), 
    .A(kqmem_addr)
);

sram_w8 #(.sram_bit(col*bw_psum)) psum_mem_instance (
    .CLK(clk),
    .D(pmem_in),
    .Q(pmem_out),
    .CEN(!(pmem_rd || pmem_wr)),
    .WEN(!pmem_wr), 
    .A(pmem_addr)
);

// SFP row instance
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
