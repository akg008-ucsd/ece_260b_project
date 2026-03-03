
module async_fifo #(
	parameter DATA_WIDTH = 24,
	parameter DEPTH = 8
)(
	input					wr_clk,
	input					rd_clk,

	input					reset,
	
	input [DATA_WIDTH-1:0]	data_in,
	input					wr,
	input					rd,

	output [DATA_WIDTH-1:0]	data_out,
	output					fifo_full,
	output					fifo_empty
);

wire [3:0] rd_ptr_gr;
wire [3:0] wr_ptr_gr;
wire [DEPTH*DATA_WIDTH-1:0] data_bus;

async_wr_fifo #(
	.DATA_WIDTH	(DATA_WIDTH),
	.DEPTH		(DEPTH)
) async_wr_fifo_instance (
	.clk		(wr_clk),
	.reset		(reset),
	
	.data_in	(data_in),
	.wr			(wr),
	.rd_ptr_gr	(rd_ptr_gr),
	
	.fifo_full	(fifo_full),
	.wr_ptr_gr	(wr_ptr_gr),
	.data_out	(data_bus)
);
	
async_rd_fifo #(
	.DATA_WIDTH	(DATA_WIDTH),
	.DEPTH		(DEPTH)
) async_rd_fifo_instance (
	.clk		(rd_clk),
	.reset		(reset),
	
	.data_in	(data_bus),
	.rd			(rd),
	.wr_ptr_gr	(wr_ptr_gr),
	
	.fifo_empty	(fifo_empty),
	.rd_ptr_gr	(rd_ptr_gr),
	.data_out	(data_out)
);

endmodule
