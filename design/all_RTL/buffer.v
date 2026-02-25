module buffer (in_clk, out_clk);
  input in_clk;
  output out_clk;
	`ifndef SYN
  	buf buffer_inst (out_clk, in_clk);
	`else
	CKBD16 buf_inst (.I(in_clk), .Z(out_clk));
	`endif
endmodule


