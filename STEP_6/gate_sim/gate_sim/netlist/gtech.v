// GTECH primitive stubs for gate-level simulation

module GTECH_AND2 (A, B, Z);
    input A, B; output Z;
    assign Z = A & B;
endmodule

module GTECH_OR2 (A, B, Z);
    input A, B; output Z;
    assign Z = A | B;
endmodule

module GTECH_NOT (A, Z);
    input A; output Z;
    assign Z = ~A;
endmodule

module GTECH_BUF (A, Z);
    input A; output Z;
    assign Z = A;
endmodule

// 2-input mux (5 ports)
module SELECT_OP_2 (DATA1, DATA2, CONTROL1, CONTROL2, Z);
    input DATA1, DATA2, CONTROL1, CONTROL2;
    output Z;
    assign Z = CONTROL1 ? DATA1 : DATA2;
endmodule

// SELECT_OP: parameterized mux covering 2-input, 8-input, 16-input variants
module SELECT_OP (DATA1, DATA2, CONTROL1, CONTROL2,
                  DATA3, DATA4, DATA5, DATA6, DATA7, DATA8,
                  DATA9, DATA10, DATA11, DATA12, DATA13, DATA14, DATA15, DATA16,
                  CONTROL3, CONTROL4, CONTROL5, CONTROL6, CONTROL7, CONTROL8,
                  CONTROL9, CONTROL10, CONTROL11, CONTROL12,
                  CONTROL13, CONTROL14, CONTROL15, CONTROL16,
                  Z);
    input DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7, DATA8;
    input DATA9, DATA10, DATA11, DATA12, DATA13, DATA14, DATA15, DATA16;
    input CONTROL1, CONTROL2, CONTROL3, CONTROL4;
    input CONTROL5, CONTROL6, CONTROL7, CONTROL8;
    input CONTROL9, CONTROL10, CONTROL11, CONTROL12;
    input CONTROL13, CONTROL14, CONTROL15, CONTROL16;
    output Z;

    wire [15:0] data = {DATA16,DATA15,DATA14,DATA13,DATA12,DATA11,DATA10,DATA9,
                        DATA8,DATA7,DATA6,DATA5,DATA4,DATA3,DATA2,DATA1};
    wire [15:0] ctrl = {CONTROL16,CONTROL15,CONTROL14,CONTROL13,
                        CONTROL12,CONTROL11,CONTROL10,CONTROL9,
                        CONTROL8,CONTROL7,CONTROL6,CONTROL5,
                        CONTROL4,CONTROL3,CONTROL2,CONTROL1};
    reg z_reg;
    integer i;
    always @(*) begin
        z_reg = 1'b0;
        for (i = 0; i < 16; i = i + 1)
            if (ctrl[i]) z_reg = data[i];
    end
    assign Z = z_reg;
endmodule
