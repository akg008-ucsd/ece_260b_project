module fullchip #(
    parameter col = 8,
    parameter bw = 8,
    parameter bw_psum = 2*bw+4,
    parameter bw_psum_sum = bw_psum+4,
    parameter pr = 8
)(
    input  clk, 
    input  reset,
    input  [19:0] inst,

`ifdef DUAL_CORE_EN
    input  [pr*bw-1:0] core1_mem_in,
    output [2*bw_psum*col-1:0] out, 
`endif

    output [bw_psum*col-1:0] out,
    input  [pr*bw-1:0] core0_mem_in 
);

    wire [bw_psum*col-1:0] out_core0;
    wire core0_clk;

    wire core0_fifo_ext_wr;
    wire core0_fifo_ext_rd;
    wire [bw_psum_sum-1:0] core0_sum_in;
    wire [bw_psum_sum-1:0] core0_sum_out;

    // Clock buffer
    buffer clkbuf_core0 (
        .in_clk(clk), 
        .out_clk(core0_clk)
    );


`ifdef DUAL_CORE_EN
	wire [bw_psum*col-1:0] out_core1;
	wire core1_clk;
	wire core1_fifo_ext_wr;
	wire core1_fifo_ext_rd;
	wire [bw_psum_sum-1:0] core1_sum_in;
	wire [bw_psum_sum-1:0] core1_sum_out;

	buffer clkbuf_core1 (.in_clk(clk), .out_clk(core1_clk));
	
	assign out = {out_core0, out_core1};

`else
	assign out = out_core0;
	assign core0_sum_in = {bw_psum_sum{1'b0}};
`endif	


//single core instance
    core #(
        .bw         (bw), 
        .bw_psum    (bw_psum), 
        .col        (col), 
        .pr         (pr)
    ) core_instance0 (
        .reset          (reset), 
        .clk            (core0_clk), 
        .mem_in         (core0_mem_in), 
        .fifo_ext_rd    (core0_fifo_ext_rd),
        .fifo_ext_wr    (core0_fifo_ext_wr),
        .sum_in         (core0_sum_in),
        .sum_out        (core0_sum_out),
        .out            (out_core0),
        .inst           (inst)
    );

`ifdef DUAL_CORE_EN
//2nd core instantiated
    core #(
    	.bw			(bw), 
    	.bw_psum	(bw_psum), 
    	.col		(col), 
    	.pr			(pr)
    ) core_instance1 (
        .reset			(reset), 
        .clk			(core1_clk), 
        .mem_in			(core1_mem_in), 
    
    	.fifo_ext_rd	        (core1_fifo_ext_rd),
    	.fifo_ext_wr	        (core1_fifo_ext_wr),
    	.sum_in			(core1_sum_in),
    	.sum_out		(core1_sum_out),
    
    	.out			(out_core1),
        .inst			(inst)
    );

//async_fifo instance for core0 -> core1 data transfer
	async_fifo #(
		.DATA_WIDTH	(bw_psum_sum),
		.DEPTH		(col)
	) async_fifo_core_01 (
		.wr_clk		(core0_clk),
		.rd_clk		(core1_clk),
	
		.reset		(reset),
		
		.data_in	(core0_sum_out),
		.wr		(core0_fifo_ext_wr),
		.rd		(core1_fifo_ext_rd),
	
		.data_out	(core1_sum_in),
		.fifo_full	(),
		.fifo_empty	()
	);

//async_fifo instance for core1 -> core0 data transfer
	async_fifo #(
		.DATA_WIDTH	(bw_psum_sum),
		.DEPTH		(col)
	) async_fifo_core_10 (
		.wr_clk		(core1_clk),
		.rd_clk		(core0_clk),
	
		.reset		(reset),
		
		.data_in	(core1_sum_out),
		.wr		(core1_fifo_ext_wr),
		.rd		(core0_fifo_ext_rd),
	
		.data_out	(core0_sum_in),
		.fifo_full	(),
		.fifo_empty	()
	);

`endif


endmodule
