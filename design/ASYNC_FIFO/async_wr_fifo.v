// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
// Change from original:
// wr_ptr_gr is now COMBINATIONAL (was registered with non-blocking assignment).
// In the original, wr_ptr_gr was updated inside the always block using the
// OLD wr_ptr_bin (non-blocking semantics), adding one extra clock cycle of
// latency. Combined with the 1-stage synchroniser in async_rd_fifo, the total
// write-to-visible latency was 3 cycles instead of the required 2, preventing
// per-row sfp_div in step-6 from reading the same-row sfp_acc entry.
// Making wr_ptr_gr combinational reduces the total latency to 2 cycles.
module async_wr_fifo (clk, reset, data_in, wr, rd_ptr_gr,
                      fifo_full, wr_ptr_gr, data_out);
	parameter DATA_WIDTH = 24;
	parameter DEPTH      = 8;
 
	input                              clk;
	input                              reset;
	input  [DATA_WIDTH-1:0]            data_in;
	input                              wr;
	input  [3:0]                       rd_ptr_gr;
	output                             fifo_full;
	output [3:0]                       wr_ptr_gr;
	output reg [DEPTH*DATA_WIDTH-1:0]  data_out;
 
	wire [3:0] rd_ptr_gr_sync;
	reg  [3:0] wr_ptr_bin;
	reg  [3:0] rd_ptr_bin;
 
	// Pass rd_ptr_gr through a Synchronizer
	sync sync0 (.clk(clk), .reset(reset), .in(rd_ptr_gr[0]), .out(rd_ptr_gr_sync[0]));
	sync sync1 (.clk(clk), .reset(reset), .in(rd_ptr_gr[1]), .out(rd_ptr_gr_sync[1]));
	sync sync2 (.clk(clk), .reset(reset), .in(rd_ptr_gr[2]), .out(rd_ptr_gr_sync[2]));
	sync sync3 (.clk(clk), .reset(reset), .in(rd_ptr_gr[3]), .out(rd_ptr_gr_sync[3]));
 
	assign fifo_full = (wr_ptr_bin[3] != rd_ptr_bin[3]) &&
	                   (wr_ptr_bin[2:0] == rd_ptr_bin[2:0]) ? 1 : 0;
 
	// wr_ptr_gr: Gray-encoded write pointer, now COMBINATIONAL.
	// Reflects wr_ptr_bin immediately so async_rd_fifo sees the updated
	// pointer one cycle sooner (removes the hidden 1-cycle NB-assignment delay).
	assign wr_ptr_gr[0] = wr_ptr_bin[0] ^ wr_ptr_bin[1];
	assign wr_ptr_gr[1] = wr_ptr_bin[1] ^ wr_ptr_bin[2];
	assign wr_ptr_gr[2] = wr_ptr_bin[2] ^ wr_ptr_bin[3];
	assign wr_ptr_gr[3] = wr_ptr_bin[3];
 
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			rd_ptr_bin <= 4'b0000;
			wr_ptr_bin <= 4'b0000;
			data_out   <= {DEPTH*DATA_WIDTH{1'b0}};
		end
		else begin
			rd_ptr_bin[0] <= rd_ptr_gr_sync[0] ^ rd_ptr_gr_sync[1] ^ rd_ptr_gr_sync[2] ^ rd_ptr_gr_sync[3];
			rd_ptr_bin[1] <= rd_ptr_gr_sync[1] ^ rd_ptr_gr_sync[2] ^ rd_ptr_gr_sync[3];
			rd_ptr_bin[2] <= rd_ptr_gr_sync[2] ^ rd_ptr_gr_sync[3];
			rd_ptr_bin[3] <= rd_ptr_gr_sync[3];
 
			if (wr && ~fifo_full) begin
				case (wr_ptr_bin[2:0])
					3'b000: data_out[DATA_WIDTH*1-1 : DATA_WIDTH*0] <= data_in;
					3'b001: data_out[DATA_WIDTH*2-1 : DATA_WIDTH*1] <= data_in;
					3'b010: data_out[DATA_WIDTH*3-1 : DATA_WIDTH*2] <= data_in;
					3'b011: data_out[DATA_WIDTH*4-1 : DATA_WIDTH*3] <= data_in;
					3'b100: data_out[DATA_WIDTH*5-1 : DATA_WIDTH*4] <= data_in;
					3'b101: data_out[DATA_WIDTH*6-1 : DATA_WIDTH*5] <= data_in;
					3'b110: data_out[DATA_WIDTH*7-1 : DATA_WIDTH*6] <= data_in;
					3'b111: data_out[DATA_WIDTH*8-1 : DATA_WIDTH*7] <= data_in;
				endcase
				wr_ptr_bin <= wr_ptr_bin + 1;
			end
		end
	end
 
endmodule
