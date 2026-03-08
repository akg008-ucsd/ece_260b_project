// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
//
// `define STEP_5_DUAL_PORT  ->  dual-port  (Port A = write, Port B = read)
// (default)                ->  single-port (original)

module sram_w8 (
`ifndef STEP_5_DUAL_PORT
  CLK, D, Q, CEN, WEN, A
`else
  CLK, D_A, CEN_A, WEN_A, A_A, Q_B, CEN_B, WEN_B, A_B
`endif
);

  parameter sram_bit = 160;
  input CLK;

`ifndef STEP_5_DUAL_PORT
  // Single-port signals
  input  WEN;
  input  CEN;
  input  [sram_bit-1:0] D;
  input  [2:0] A;
  output reg [sram_bit-1:0] Q;
`else
  // Dual-port signals
  // Port A: write
  input  [sram_bit-1:0] D_A;
  input  CEN_A;
  input  WEN_A;
  input  [2:0] A_A;
  // Port B: read
  output reg [sram_bit-1:0] Q_B;
  input  CEN_B;
  input  WEN_B;
  input  [2:0] A_B;
`endif

  reg [sram_bit-1:0] memory0;
  reg [sram_bit-1:0] memory1;
  reg [sram_bit-1:0] memory2;
  reg [sram_bit-1:0] memory3;
  reg [sram_bit-1:0] memory4;
  reg [sram_bit-1:0] memory5;
  reg [sram_bit-1:0] memory6;
  reg [sram_bit-1:0] memory7;

  always @ (posedge CLK) begin

`ifndef STEP_5_DUAL_PORT
    // Single-port: read and write share CEN/WEN/A
    if (!CEN && WEN) begin // read
      case (A)
        3'b000: Q <= memory0;
        3'b001: Q <= memory1;
        3'b010: Q <= memory2;
        3'b011: Q <= memory3;
        3'b100: Q <= memory4;
        3'b101: Q <= memory5;
        3'b110: Q <= memory6;
        3'b111: Q <= memory7;
      endcase
    end
    else if (!CEN && !WEN) begin // write
      case (A)
        3'b000: memory0 <= D;
        3'b001: memory1 <= D;
        3'b010: memory2 <= D;
        3'b011: memory3 <= D;
        3'b100: memory4 <= D;
        3'b101: memory5 <= D;
        3'b110: memory6 <= D;
        3'b111: memory7 <= D;
      endcase
    end
`else
    // Dual-port: Port A write and Port B read are independent
    // Port A: write
    if (!CEN_A && !WEN_A) begin
      case (A_A)
        3'b000: memory0 <= D_A;
        3'b001: memory1 <= D_A;
        3'b010: memory2 <= D_A;
        3'b011: memory3 <= D_A;
        3'b100: memory4 <= D_A;
        3'b101: memory5 <= D_A;
        3'b110: memory6 <= D_A;
        3'b111: memory7 <= D_A;
      endcase
    end
    // Port B: read (returns OLD value on same-cycle concurrent write)
    if (!CEN_B && WEN_B) begin
      case (A_B)
        3'b000: Q_B <= memory0;
        3'b001: Q_B <= memory1;
        3'b010: Q_B <= memory2;
        3'b011: Q_B <= memory3;
        3'b100: Q_B <= memory4;
        3'b101: Q_B <= memory5;
        3'b110: Q_B <= memory6;
        3'b111: Q_B <= memory7;
      endcase
    end
`endif

  end
endmodule

