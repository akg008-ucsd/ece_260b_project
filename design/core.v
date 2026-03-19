// Created by prof. Mingu Kang @VVIP Lab, UCSD ECE
// Please do not spread this code without permission
// Conditional compilation:
//   `define STEP_5_DUAL_PORT  ->  instantiates dual-port SRAMs
//   `define SPARSITY_AWARE    ->  adds threshold input and sparse_row output
//                                 wired through to sfp_row instance
//
// SPARSITY_AWARE gate-saving observability note:
//   When sparse_row=1, sfp_row gates all sfp_out lanes to zero (power saving).
//   This gating is NOT visible on the `out` port because `out = pmem_out` always
//   -- sfp_out is only committed to pmem when pmem_wr=1 (which the controller
//   skips for sparse rows). The gate saving is confirmed structurally by
//   inspecting the sfp_out assign statements in sfp_row.v (SPARSITY_AWARE block).
//   The sparse_row signal itself is exposed on the top-level port and is the
//   correct signal for the controller to observe/act upon (cycle saving).
module core #(
parameter col = 8,
parameter bw = 8,
parameter bw_psum = 2*bw+4,
parameter bw_psum_sum = bw_psum+4,
parameter pr = 8)(
    input clk,
    input reset,
    input [pr*bw-1:0] mem_in,
    input [bw_psum_sum-1:0] sum_in,
    input [19:0] inst,
    output fifo_ext_rd,
    output fifo_ext_wr,
    output [bw_psum_sum-1:0] sum_out,
    output [bw_psum*col-1:0] out
    `ifdef SPARSITY_AWARE
    ,
    input  [bw_psum_sum-1:0] threshold,
    output                   sparse_row
    `endif
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
`ifdef CLK_GATE
wire [pr-1:0] mac_in_zero;
`endif
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
// Assign output -- always driven from pmem_out.
// sfp_out gate saving (sparse_row=1 -> sfp_out=0) is confirmed structurally
// in sfp_row.v; it takes effect at the pmem write stage (pmem_wr with sfp_out=0)
// rather than being directly observable on this port.
assign out = pmem_out;
genvar i;
generate
    for (i = 0; i<col; i=i+1) begin : loop
`ifdef CLK_GATE
        assign mac_in_zero[i] = ~(|mac_in[bw*(i+1)-1:bw*i]);
`endif
    end
endgenerate
wire [bw_psum*col-1:0] pmem_mux_in = pmem_src_sel ? ofifo_out : sfp_out;
// MAC input selection: load phase -> kmem data, execute phase -> qmem data
reg mac_in_mux_sel;
always @(posedge clk or posedge reset) begin
    if (reset) mac_in_mux_sel <= 1'b0;
    else       mac_in_mux_sel <= mac_inst[0];
end
assign mac_in = mac_in_mux_sel ? kmem_out : qmem_out;
// MAC array
mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
    .in(mac_in),
    .clk(clk),
    .reset(reset),
    .inst(mac_inst),
`ifdef CLK_GATE
    .in_zero(mac_in_zero),
`endif
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
// -----------------------------------------------------------------------
// QMEM instantiation
// -----------------------------------------------------------------------
`ifndef STEP_5_DUAL_PORT
sram_w16 #(.sram_bit(pr*bw)) qmem_instance (
    .CLK (clk),
    .D   (mem_in),
    .Q   (qmem_out),
    .CEN (!(qmem_wr | qmem_rd)),
    .WEN (!qmem_wr),
    .A   (kqmem_addr)
);
`else
sram_w16 #(.sram_bit(pr*bw)) qmem_instance (
    .CLK   (clk),
    .D_A   (mem_in),
    .CEN_A (!qmem_wr),
    .WEN_A (1'b0),
    .A_A   (kqmem_addr),
    .Q_B   (qmem_out),
    .CEN_B (!qmem_rd),
    .WEN_B (1'b1),
    .A_B   (kqmem_addr)
);
`endif
// -----------------------------------------------------------------------
// KMEM instantiation
// -----------------------------------------------------------------------
`ifndef STEP_5_DUAL_PORT
sram_w16 #(.sram_bit(pr*bw)) kmem_instance (
    .CLK (clk),
    .D   (mem_in),
    .Q   (kmem_out),
    .CEN (!(kmem_wr | kmem_rd)),
    .WEN (!kmem_wr),
    .A   (kqmem_addr)
);
`else
sram_w16 #(.sram_bit(pr*bw)) kmem_instance (
    .CLK   (clk),
    .D_A   (mem_in),
    .CEN_A (!kmem_wr),
    .WEN_A (1'b0),
    .A_A   (kqmem_addr),
    .Q_B   (kmem_out),
    .CEN_B (!kmem_rd),
    .WEN_B (1'b1),
    .A_B   (kqmem_addr)
);
`endif
// -----------------------------------------------------------------------
// PMEM instantiation
// -----------------------------------------------------------------------
`ifndef STEP_5_DUAL_PORT
sram_w8 #(.sram_bit(col*bw_psum)) psum_mem_instance (
    .CLK (clk),
    .D   (pmem_mux_in),
    .Q   (pmem_out),
    .CEN (!(pmem_wr | pmem_rd)),
    .WEN (!pmem_wr),
    .A   (pmem_addr)
);
`else
sram_w8 #(.sram_bit(col*bw_psum)) psum_mem_instance (
    .CLK   (clk),
    .D_A   (pmem_mux_in),
    .CEN_A (!pmem_wr),
    .WEN_A (1'b0),
    .A_A   (pmem_addr),
    .Q_B   (pmem_out),
    .CEN_B (!pmem_rd),
    .WEN_B (1'b1),
    .A_B   (pmem_addr)
);
`endif
// SFP row
sfp_row #(.bw_psum(bw_psum), .col(col), .bw(bw)) sfp_instance (
    .clk        (clk),
    .reset      (reset),
    .div        (sfp_div),
    .acc        (sfp_acc),
    .fifo_ext_rd(fifo_ext_rd),
    .fifo_ext_wr(fifo_ext_wr),
    .sum_in     (sum_in),
    .sfp_in     (pmem_out),
    .sfp_out    (sfp_out),
    .sum_out    (sum_out)
    `ifdef SPARSITY_AWARE
    ,
    .threshold  (threshold),
    .sparse_row (sparse_row)
    `endif
);
endmodule
