module async_rd_fifo #(
	parameter DATA_WIDTH = 24,
	parameter DEPTH		 = 8		
)(
input 							clk,
input 							reset,

input [DEPTH*DATA_WIDTH-1:0]	data_in,
input							rd,
input [3:0]			 			wr_ptr_gr,

output							fifo_empty,
output reg [3:0]				rd_ptr_gr,
output reg [DATA_WIDTH-1:0]		data_out
);

wire [3:0] wr_ptr_gr_sync;
reg  [3:0] wr_ptr_bin;
reg  [3:0] rd_ptr_bin;

//Pass wr_ptr_gr through a Synchronizer
sync sync0 (.clk (clk), .reset(reset), .in (wr_ptr_gr[0]), .out (wr_ptr_gr_sync[0]));
sync sync1 (.clk (clk), .reset(reset), .in (wr_ptr_gr[1]), .out (wr_ptr_gr_sync[1]));
sync sync2 (.clk (clk), .reset(reset), .in (wr_ptr_gr[2]), .out (wr_ptr_gr_sync[2]));
sync sync3 (.clk (clk), .reset(reset), .in (wr_ptr_gr[3]), .out (wr_ptr_gr_sync[3]));

assign fifo_empty = (wr_ptr_bin == rd_ptr_bin) ? 1 : 0;

always @ (posedge clk or posedge reset) begin
	if (reset) begin
		wr_ptr_bin 	<= 4'b0000;
		rd_ptr_bin 	<= 4'b0000;
		rd_ptr_gr 	<= 4'b0000;
		data_out 	<= 20'b0;
	end
	else begin
		wr_ptr_bin[0] <= wr_ptr_gr_sync[0] ^ wr_ptr_gr_sync[1] ^ wr_ptr_gr_sync[2] ^ wr_ptr_gr_sync[3];
		wr_ptr_bin[1] <= wr_ptr_gr_sync[1] ^ wr_ptr_gr_sync[2] ^ wr_ptr_gr_sync[3];
		wr_ptr_bin[2] <= wr_ptr_gr_sync[2] ^ wr_ptr_gr_sync[3];
		wr_ptr_bin[3] <= wr_ptr_gr_sync[3];

		rd_ptr_gr[0]  <= rd_ptr_bin[0] ^ rd_ptr_bin[1];
		rd_ptr_gr[1]  <= rd_ptr_bin[1] ^ rd_ptr_bin[2];
		rd_ptr_gr[2]  <= rd_ptr_bin[2] ^ rd_ptr_bin[3];
		rd_ptr_gr[3]  <= rd_ptr_bin[3];

		if(rd && ~fifo_empty) begin
			data_out	<= 	(rd_ptr_bin[3:0] == 3'b000) ? data_in[DATA_WIDTH-1:0] :
							(rd_ptr_bin[3:0] == 3'b001) ? data_in[DATA_WIDTH*2-1:DATA_WIDTH*1] :
							(rd_ptr_bin[3:0] == 3'b010) ? data_in[DATA_WIDTH*3-1:DATA_WIDTH*2] :
							(rd_ptr_bin[3:0] == 3'b011) ? data_in[DATA_WIDTH*4-1:DATA_WIDTH*3] :
							(rd_ptr_bin[3:0] == 3'b100) ? data_in[DATA_WIDTH*5-1:DATA_WIDTH*4] :
							(rd_ptr_bin[3:0] == 3'b101) ? data_in[DATA_WIDTH*6-1:DATA_WIDTH*5] :
							(rd_ptr_bin[3:0] == 3'b110) ? data_in[DATA_WIDTH*7-1:DATA_WIDTH*6] : data_in[DATA_WIDTH*8-1:DATA_WIDTH*7];
			rd_ptr_bin  <= rd_ptr_bin + 1; 
		end
	end	
end

endmodule
