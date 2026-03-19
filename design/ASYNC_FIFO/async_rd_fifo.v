// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
// Changes from original:
// 1. wr_ptr synchroniser reduced to 1 stage (was 2 stages via sync0..sync3).
//    wr_ptr_bin is now COMBINATIONAL from wr_ptr_gr_sync (was registered).
//    Result: write-pointer visible in rd domain after 2 cycles instead of 3.
//    This lets each per-row sfp_div in step-6 successfully read the entry
//    written by the same row's sfp_acc (timing gap = 3 cycles > 2 cycle prop).
// 2. Two-stage rd_happened flag (rd_happened_1, rd_happened_2):
//    data_out is forced to 0 only when fifo_empty=1 AND both rd_happened
//    stages are 0. A single-stage flag was cleared one cycle too early
//    (at div_2q time, rd=0 so the flag went 0, zeroing data_out before
//    div_2q could use it). The two-stage version holds the valid data_out
//    across both div_q and div_2q cycles.
module async_rd_fifo (clk, reset, data_in, rd, wr_ptr_gr,
                      fifo_empty, rd_ptr_gr, data_out);
	parameter DATA_WIDTH = 24;
	parameter DEPTH      = 8;
 
	input                          clk;
	input                          reset;
	input  [DEPTH*DATA_WIDTH-1:0]  data_in;
	input                          rd;
	input  [3:0]                   wr_ptr_gr;
	output                         fifo_empty;
	output reg [3:0]               rd_ptr_gr;
	output     [DATA_WIDTH-1:0]    data_out;
 
	// One synchroniser stage (was two sync instances)
	reg  [3:0] wr_ptr_gr_sync;
 
	// Combinational Gray-to-binary (was registered inside always block)
	wire [3:0] wr_ptr_bin;
	assign wr_ptr_bin[0] = wr_ptr_gr_sync[0] ^ wr_ptr_gr_sync[1] ^ wr_ptr_gr_sync[2] ^ wr_ptr_gr_sync[3];
	assign wr_ptr_bin[1] = wr_ptr_gr_sync[1] ^ wr_ptr_gr_sync[2] ^ wr_ptr_gr_sync[3];
	assign wr_ptr_bin[2] = wr_ptr_gr_sync[2] ^ wr_ptr_gr_sync[3];
	assign wr_ptr_bin[3] = wr_ptr_gr_sync[3];
 
	reg [3:0] rd_ptr_bin;
 
	assign fifo_empty = (wr_ptr_bin == rd_ptr_bin) ? 1 : 0;
 
	reg [DATA_WIDTH-1:0] data_out_reg;
 
	// Two-stage rd_happened: rd_happened_1 is set at div_q, rd_happened_2
	// is set at div_2q. data_out is held valid across both cycles.
	reg rd_happened_1;
	reg rd_happened_2;
 
	assign data_out = (fifo_empty && !rd_happened_1 && !rd_happened_2) ?
	                  {DATA_WIDTH{1'b0}} : data_out_reg;
 
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			wr_ptr_gr_sync <= 4'b0000;
			rd_ptr_bin     <= 4'b0000;
			rd_ptr_gr      <= 4'b0000;
			data_out_reg   <= {DATA_WIDTH{1'b0}};
			rd_happened_1  <= 1'b0;
			rd_happened_2  <= 1'b0;
		end
		else begin
			// Single sync stage for wr_ptr_gr
			wr_ptr_gr_sync <= wr_ptr_gr;
 
			// Gray-encode rd_ptr for write domain
			rd_ptr_gr[0] <= rd_ptr_bin[0] ^ rd_ptr_bin[1];
			rd_ptr_gr[1] <= rd_ptr_bin[1] ^ rd_ptr_bin[2];
			rd_ptr_gr[2] <= rd_ptr_bin[2] ^ rd_ptr_bin[3];
			rd_ptr_gr[3] <= rd_ptr_bin[3];
 
			// Shift the rd_happened pipeline
			rd_happened_2 <= rd_happened_1;
			rd_happened_1 <= (rd && ~fifo_empty);
 
			if (rd && ~fifo_empty) begin
				data_out_reg <=
					(rd_ptr_bin[3:0] == 4'b0000) ? data_in[DATA_WIDTH*1-1 : DATA_WIDTH*0] :
					(rd_ptr_bin[3:0] == 4'b0001) ? data_in[DATA_WIDTH*2-1 : DATA_WIDTH*1] :
					(rd_ptr_bin[3:0] == 4'b0010) ? data_in[DATA_WIDTH*3-1 : DATA_WIDTH*2] :
					(rd_ptr_bin[3:0] == 4'b0011) ? data_in[DATA_WIDTH*4-1 : DATA_WIDTH*3] :
					(rd_ptr_bin[3:0] == 4'b0100) ? data_in[DATA_WIDTH*5-1 : DATA_WIDTH*4] :
					(rd_ptr_bin[3:0] == 4'b0101) ? data_in[DATA_WIDTH*6-1 : DATA_WIDTH*5] :
					(rd_ptr_bin[3:0] == 4'b0110) ? data_in[DATA_WIDTH*7-1 : DATA_WIDTH*6] :
					                               data_in[DATA_WIDTH*8-1 : DATA_WIDTH*7] ;
				rd_ptr_bin <= rd_ptr_bin + 1;
			end
		end
	end
 
endmodule
