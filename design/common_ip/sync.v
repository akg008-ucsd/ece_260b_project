// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sync(clk, reset, in, out);

input  in; 
input  clk;
input  reset;
output out;

reg    int1; 
reg    int2; 

assign out = int2;

always @ (posedge clk or posedge reset) begin
	if(reset) begin
		int1 <= 1'b0;
		int2 <= 1'b0;
	end
	else begin
   		int1 <= in;
   		int2 <= int1;
	end
end

endmodule
