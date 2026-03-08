// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
//
// `define STEP_5_DUAL_PORT  ->  dual-port  (Port A = write, Port B = read)
// (default)                ->  single-port (original)

module sram_w16 (
`ifndef STEP_5_DUAL_PORT
  CLK, D, Q, CEN, WEN, A
`else
  CLK, D_A, CEN_A, WEN_A, A_A, Q_B, CEN_B, WEN_B, A_B
`endif
);

  parameter sram_bit = 64;
  input CLK;

`ifndef STEP_5_DUAL_PORT
  // Single-port signals
  input  WEN;
  input  CEN;
  input  [sram_bit-1:0] D;
  input  [3:0] A;
  output reg [sram_bit-1:0] Q;
`else
  // Dual-port signals
  // Port A: write
  input  [sram_bit-1:0] D_A;
  input  CEN_A;
  input  WEN_A;
  input  [3:0] A_A;
  // Port B: read
  output reg [sram_bit-1:0] Q_B;
  input  CEN_B;
  input  WEN_B;
  input  [3:0] A_B;
`endif

  reg [sram_bit-1:0] memory0;
  reg [sram_bit-1:0] memory1;
  reg [sram_bit-1:0] memory2;
  reg [sram_bit-1:0] memory3;
  reg [sram_bit-1:0] memory4;
  reg [sram_bit-1:0] memory5;
  reg [sram_bit-1:0] memory6;
  reg [sram_bit-1:0] memory7;
  reg [sram_bit-1:0] memory8;
  reg [sram_bit-1:0] memory9;
  reg [sram_bit-1:0] memory10;
  reg [sram_bit-1:0] memory11;
  reg [sram_bit-1:0] memory12;
  reg [sram_bit-1:0] memory13;
  reg [sram_bit-1:0] memory14;
  reg [sram_bit-1:0] memory15;

  always @ (posedge CLK) begin

`ifndef STEP_5_DUAL_PORT
    // Single-port: read and write share CEN/WEN/A
    if (!CEN && WEN) begin // read
      case (A)
        4'b0000: Q <= memory0;
        4'b0001: Q <= memory1;
        4'b0010: Q <= memory2;
        4'b0011: Q <= memory3;
        4'b0100: Q <= memory4;
        4'b0101: Q <= memory5;
        4'b0110: Q <= memory6;
        4'b0111: Q <= memory7;
        4'b1000: Q <= memory8;
        4'b1001: Q <= memory9;
        4'b1010: Q <= memory10;
        4'b1011: Q <= memory11;
        4'b1100: Q <= memory12;
        4'b1101: Q <= memory13;
        4'b1110: Q <= memory14;
        4'b1111: Q <= memory15;
      endcase
    end
    else if (!CEN && !WEN) begin // write
      case (A)
        4'b0000: memory0  <= D;
        4'b0001: memory1  <= D;
        4'b0010: memory2  <= D;
        4'b0011: memory3  <= D;
        4'b0100: memory4  <= D;
        4'b0101: memory5  <= D;
        4'b0110: memory6  <= D;
        4'b0111: memory7  <= D;
        4'b1000: memory8  <= D;
        4'b1001: memory9  <= D;
        4'b1010: memory10 <= D;
        4'b1011: memory11 <= D;
        4'b1100: memory12 <= D;
        4'b1101: memory13 <= D;
        4'b1110: memory14 <= D;
        4'b1111: memory15 <= D;
      endcase
    end
`else
    // Dual-port: Port A write and Port B read are independent
    // Port A: write
    if (!CEN_A && !WEN_A) begin
      case (A_A)
        4'b0000: memory0  <= D_A;
        4'b0001: memory1  <= D_A;
        4'b0010: memory2  <= D_A;
        4'b0011: memory3  <= D_A;
        4'b0100: memory4  <= D_A;
        4'b0101: memory5  <= D_A;
        4'b0110: memory6  <= D_A;
        4'b0111: memory7  <= D_A;
        4'b1000: memory8  <= D_A;
        4'b1001: memory9  <= D_A;
        4'b1010: memory10 <= D_A;
        4'b1011: memory11 <= D_A;
        4'b1100: memory12 <= D_A;
        4'b1101: memory13 <= D_A;
        4'b1110: memory14 <= D_A;
        4'b1111: memory15 <= D_A;
      endcase
    end
    // Port B: read (returns OLD value on same-cycle concurrent write)
    if (!CEN_B && WEN_B) begin
      case (A_B)
        4'b0000: Q_B <= memory0;
        4'b0001: Q_B <= memory1;
        4'b0010: Q_B <= memory2;
        4'b0011: Q_B <= memory3;
        4'b0100: Q_B <= memory4;
        4'b0101: Q_B <= memory5;
        4'b0110: Q_B <= memory6;
        4'b0111: Q_B <= memory7;
        4'b1000: Q_B <= memory8;
        4'b1001: Q_B <= memory9;
        4'b1010: Q_B <= memory10;
        4'b1011: Q_B <= memory11;
        4'b1100: Q_B <= memory12;
        4'b1101: Q_B <= memory13;
        4'b1110: Q_B <= memory14;
        4'b1111: Q_B <= memory15;
      endcase
    end
`endif

  end
endmodule
