/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Mon Mar  9 22:05:06 2026
/////////////////////////////////////////////////////////////


module buffer ( in_clk, out_clk );
  input in_clk;
  output out_clk;

  tri   in_clk;
  assign out_clk = in_clk;

endmodule


module core_col8_bw8_bw_psum20_pr8 ( clk, reset, mem_in, sum_in, inst, 
        fifo_ext_rd, fifo_ext_wr, sum_out, out );
  input [63:0] mem_in;
  input [23:0] sum_in;
  input [19:0] inst;
  output [23:0] sum_out;
  output [159:0] out;
  input clk, reset;
  output fifo_ext_rd, fifo_ext_wr;
  wire   mac_in_mux_sel, N6, N7, N8, n25, n26, n27, n51, n52,
         SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2,
         SYNOPSYS_UNCONNECTED_3, SYNOPSYS_UNCONNECTED_4,
         SYNOPSYS_UNCONNECTED_5, SYNOPSYS_UNCONNECTED_6,
         SYNOPSYS_UNCONNECTED_7, SYNOPSYS_UNCONNECTED_8,
         SYNOPSYS_UNCONNECTED_9, SYNOPSYS_UNCONNECTED_10,
         SYNOPSYS_UNCONNECTED_11, SYNOPSYS_UNCONNECTED_12,
         SYNOPSYS_UNCONNECTED_13, SYNOPSYS_UNCONNECTED_14,
         SYNOPSYS_UNCONNECTED_15, SYNOPSYS_UNCONNECTED_16,
         SYNOPSYS_UNCONNECTED_17, SYNOPSYS_UNCONNECTED_18,
         SYNOPSYS_UNCONNECTED_19, SYNOPSYS_UNCONNECTED_20,
         SYNOPSYS_UNCONNECTED_21, SYNOPSYS_UNCONNECTED_22,
         SYNOPSYS_UNCONNECTED_23, SYNOPSYS_UNCONNECTED_24;
  tri   clk;
  tri   reset;
  tri   [63:0] mem_in;
  tri   [1:24] n;
  tri   [159:0] out;
  tri   [159:0] pmem_mux_in;
  tri   [159:0] ofifo_out;
  tri   [159:0] sfp_out;
  tri   [63:0] mac_in;
  tri   [63:0] kmem_out;
  tri   [63:0] qmem_out;
  tri   [7:0] ofifo_wr;
  tri   [159:0] array_out;
  tri   n_0_net_;
  tri   n_1_net_;
  tri   n_2_net_;
  tri   n_3_net_;
  tri   n_4_net_;
  tri   n_5_net_;

  mac_array mac_array_instance ( .in(mac_in), .clk(clk), .reset(reset), .inst(
        inst[7:6]), .fifo_wr(ofifo_wr), .out(array_out) );
  ofifo ofifo_instance ( .reset(reset), .clk(clk), .in(array_out), .wr(
        ofifo_wr), .rd(inst[15]), .out(ofifo_out) );
  sram_w16 qmem_instance ( .CLK(clk), .D(mem_in), .Q(qmem_out), .CEN(n_0_net_), 
        .WEN(n_1_net_), .A(inst[14:11]) );
  sram_w16 kmem_instance ( .CLK(clk), .D(mem_in), .Q(kmem_out), .CEN(n_2_net_), 
        .WEN(n_3_net_), .A(inst[14:11]) );
  sram_w8 psum_mem_instance ( .CLK(clk), .D(pmem_mux_in), .Q(out), .CEN(
        n_4_net_), .WEN(n_5_net_), .A(inst[10:8]) );
  sfp_row sfp_instance ( .clk(clk), .reset(reset), .div(inst[17]), .acc(
        inst[16]), .sum_in({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0}), .sfp_in(out), .sfp_out(sfp_out), .sum_out({
        SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2, SYNOPSYS_UNCONNECTED_3, 
        SYNOPSYS_UNCONNECTED_4, SYNOPSYS_UNCONNECTED_5, SYNOPSYS_UNCONNECTED_6, 
        SYNOPSYS_UNCONNECTED_7, SYNOPSYS_UNCONNECTED_8, SYNOPSYS_UNCONNECTED_9, 
        SYNOPSYS_UNCONNECTED_10, SYNOPSYS_UNCONNECTED_11, 
        SYNOPSYS_UNCONNECTED_12, SYNOPSYS_UNCONNECTED_13, 
        SYNOPSYS_UNCONNECTED_14, SYNOPSYS_UNCONNECTED_15, 
        SYNOPSYS_UNCONNECTED_16, SYNOPSYS_UNCONNECTED_17, 
        SYNOPSYS_UNCONNECTED_18, SYNOPSYS_UNCONNECTED_19, 
        SYNOPSYS_UNCONNECTED_20, SYNOPSYS_UNCONNECTED_21, 
        SYNOPSYS_UNCONNECTED_22, SYNOPSYS_UNCONNECTED_23, 
        SYNOPSYS_UNCONNECTED_24}) );
  INVD0 U32 ( .I(inst[4]), .ZN(n_1_net_) );
  INVD0 U33 ( .I(N6), .ZN(n_0_net_) );
  INVD0 U34 ( .I(inst[2]), .ZN(n_3_net_) );
  INVD0 U35 ( .I(N7), .ZN(n_2_net_) );
  INVD0 U36 ( .I(inst[0]), .ZN(n_5_net_) );
  INVD0 U37 ( .I(N8), .ZN(n_4_net_) );
  AO22D0 U38 ( .A1(mac_in_mux_sel), .A2(kmem_out[63]), .B1(n26), .B2(
        qmem_out[63]), .Z(mac_in[63]) );
  AO22D0 U39 ( .A1(mac_in_mux_sel), .A2(kmem_out[62]), .B1(n26), .B2(
        qmem_out[62]), .Z(mac_in[62]) );
  AO22D0 U40 ( .A1(mac_in_mux_sel), .A2(kmem_out[61]), .B1(n26), .B2(
        qmem_out[61]), .Z(mac_in[61]) );
  AO22D0 U41 ( .A1(mac_in_mux_sel), .A2(kmem_out[60]), .B1(n26), .B2(
        qmem_out[60]), .Z(mac_in[60]) );
  AO22D0 U42 ( .A1(mac_in_mux_sel), .A2(kmem_out[59]), .B1(n26), .B2(
        qmem_out[59]), .Z(mac_in[59]) );
  AO22D0 U43 ( .A1(mac_in_mux_sel), .A2(kmem_out[58]), .B1(n26), .B2(
        qmem_out[58]), .Z(mac_in[58]) );
  AO22D0 U44 ( .A1(mac_in_mux_sel), .A2(kmem_out[57]), .B1(n26), .B2(
        qmem_out[57]), .Z(mac_in[57]) );
  AO22D0 U45 ( .A1(mac_in_mux_sel), .A2(kmem_out[56]), .B1(n26), .B2(
        qmem_out[56]), .Z(mac_in[56]) );
  AO22D0 U46 ( .A1(mac_in_mux_sel), .A2(kmem_out[55]), .B1(n26), .B2(
        qmem_out[55]), .Z(mac_in[55]) );
  AO22D0 U47 ( .A1(mac_in_mux_sel), .A2(kmem_out[54]), .B1(n26), .B2(
        qmem_out[54]), .Z(mac_in[54]) );
  AO22D0 U48 ( .A1(mac_in_mux_sel), .A2(kmem_out[53]), .B1(n26), .B2(
        qmem_out[53]), .Z(mac_in[53]) );
  AO22D0 U49 ( .A1(mac_in_mux_sel), .A2(kmem_out[52]), .B1(n26), .B2(
        qmem_out[52]), .Z(mac_in[52]) );
  AO22D0 U50 ( .A1(mac_in_mux_sel), .A2(kmem_out[51]), .B1(n26), .B2(
        qmem_out[51]), .Z(mac_in[51]) );
  AO22D0 U51 ( .A1(mac_in_mux_sel), .A2(kmem_out[50]), .B1(n26), .B2(
        qmem_out[50]), .Z(mac_in[50]) );
  AO22D0 U52 ( .A1(mac_in_mux_sel), .A2(kmem_out[49]), .B1(n26), .B2(
        qmem_out[49]), .Z(mac_in[49]) );
  AO22D0 U53 ( .A1(mac_in_mux_sel), .A2(kmem_out[48]), .B1(n26), .B2(
        qmem_out[48]), .Z(mac_in[48]) );
  AO22D0 U54 ( .A1(mac_in_mux_sel), .A2(kmem_out[47]), .B1(n26), .B2(
        qmem_out[47]), .Z(mac_in[47]) );
  AO22D0 U55 ( .A1(mac_in_mux_sel), .A2(kmem_out[46]), .B1(n26), .B2(
        qmem_out[46]), .Z(mac_in[46]) );
  AO22D0 U56 ( .A1(mac_in_mux_sel), .A2(kmem_out[45]), .B1(n26), .B2(
        qmem_out[45]), .Z(mac_in[45]) );
  AO22D0 U57 ( .A1(mac_in_mux_sel), .A2(kmem_out[44]), .B1(n26), .B2(
        qmem_out[44]), .Z(mac_in[44]) );
  AO22D0 U58 ( .A1(mac_in_mux_sel), .A2(kmem_out[43]), .B1(n26), .B2(
        qmem_out[43]), .Z(mac_in[43]) );
  AO22D0 U59 ( .A1(mac_in_mux_sel), .A2(kmem_out[42]), .B1(n26), .B2(
        qmem_out[42]), .Z(mac_in[42]) );
  AO22D0 U60 ( .A1(mac_in_mux_sel), .A2(kmem_out[41]), .B1(n26), .B2(
        qmem_out[41]), .Z(mac_in[41]) );
  AO22D0 U61 ( .A1(mac_in_mux_sel), .A2(kmem_out[40]), .B1(n26), .B2(
        qmem_out[40]), .Z(mac_in[40]) );
  AO22D0 U62 ( .A1(mac_in_mux_sel), .A2(kmem_out[39]), .B1(n26), .B2(
        qmem_out[39]), .Z(mac_in[39]) );
  AO22D0 U63 ( .A1(mac_in_mux_sel), .A2(kmem_out[38]), .B1(n26), .B2(
        qmem_out[38]), .Z(mac_in[38]) );
  AO22D0 U64 ( .A1(mac_in_mux_sel), .A2(kmem_out[37]), .B1(n26), .B2(
        qmem_out[37]), .Z(mac_in[37]) );
  AO22D0 U65 ( .A1(mac_in_mux_sel), .A2(kmem_out[36]), .B1(n26), .B2(
        qmem_out[36]), .Z(mac_in[36]) );
  AO22D0 U66 ( .A1(mac_in_mux_sel), .A2(kmem_out[35]), .B1(n26), .B2(
        qmem_out[35]), .Z(mac_in[35]) );
  AO22D0 U67 ( .A1(mac_in_mux_sel), .A2(kmem_out[34]), .B1(n26), .B2(
        qmem_out[34]), .Z(mac_in[34]) );
  AO22D0 U68 ( .A1(mac_in_mux_sel), .A2(kmem_out[33]), .B1(n26), .B2(
        qmem_out[33]), .Z(mac_in[33]) );
  AO22D0 U69 ( .A1(mac_in_mux_sel), .A2(kmem_out[32]), .B1(n26), .B2(
        qmem_out[32]), .Z(mac_in[32]) );
  AO22D0 U70 ( .A1(mac_in_mux_sel), .A2(kmem_out[31]), .B1(n26), .B2(
        qmem_out[31]), .Z(mac_in[31]) );
  AO22D0 U71 ( .A1(mac_in_mux_sel), .A2(kmem_out[30]), .B1(n26), .B2(
        qmem_out[30]), .Z(mac_in[30]) );
  AO22D0 U72 ( .A1(mac_in_mux_sel), .A2(kmem_out[29]), .B1(n26), .B2(
        qmem_out[29]), .Z(mac_in[29]) );
  AO22D0 U73 ( .A1(mac_in_mux_sel), .A2(kmem_out[28]), .B1(n26), .B2(
        qmem_out[28]), .Z(mac_in[28]) );
  AO22D0 U74 ( .A1(mac_in_mux_sel), .A2(kmem_out[27]), .B1(n26), .B2(
        qmem_out[27]), .Z(mac_in[27]) );
  AO22D0 U75 ( .A1(mac_in_mux_sel), .A2(kmem_out[26]), .B1(n26), .B2(
        qmem_out[26]), .Z(mac_in[26]) );
  AO22D0 U76 ( .A1(mac_in_mux_sel), .A2(kmem_out[25]), .B1(n26), .B2(
        qmem_out[25]), .Z(mac_in[25]) );
  AO22D0 U77 ( .A1(mac_in_mux_sel), .A2(kmem_out[24]), .B1(n26), .B2(
        qmem_out[24]), .Z(mac_in[24]) );
  AO22D0 U78 ( .A1(mac_in_mux_sel), .A2(kmem_out[23]), .B1(n26), .B2(
        qmem_out[23]), .Z(mac_in[23]) );
  AO22D0 U79 ( .A1(mac_in_mux_sel), .A2(kmem_out[22]), .B1(n26), .B2(
        qmem_out[22]), .Z(mac_in[22]) );
  AO22D0 U80 ( .A1(mac_in_mux_sel), .A2(kmem_out[21]), .B1(n26), .B2(
        qmem_out[21]), .Z(mac_in[21]) );
  AO22D0 U81 ( .A1(mac_in_mux_sel), .A2(kmem_out[20]), .B1(n26), .B2(
        qmem_out[20]), .Z(mac_in[20]) );
  AO22D0 U82 ( .A1(mac_in_mux_sel), .A2(kmem_out[19]), .B1(n26), .B2(
        qmem_out[19]), .Z(mac_in[19]) );
  AO22D0 U83 ( .A1(mac_in_mux_sel), .A2(kmem_out[18]), .B1(n26), .B2(
        qmem_out[18]), .Z(mac_in[18]) );
  AO22D0 U84 ( .A1(mac_in_mux_sel), .A2(kmem_out[17]), .B1(n26), .B2(
        qmem_out[17]), .Z(mac_in[17]) );
  AO22D0 U85 ( .A1(mac_in_mux_sel), .A2(kmem_out[16]), .B1(n26), .B2(
        qmem_out[16]), .Z(mac_in[16]) );
  AO22D0 U86 ( .A1(mac_in_mux_sel), .A2(kmem_out[15]), .B1(n26), .B2(
        qmem_out[15]), .Z(mac_in[15]) );
  AO22D0 U87 ( .A1(mac_in_mux_sel), .A2(kmem_out[14]), .B1(n26), .B2(
        qmem_out[14]), .Z(mac_in[14]) );
  AO22D0 U88 ( .A1(mac_in_mux_sel), .A2(kmem_out[13]), .B1(n26), .B2(
        qmem_out[13]), .Z(mac_in[13]) );
  AO22D0 U89 ( .A1(mac_in_mux_sel), .A2(kmem_out[12]), .B1(n26), .B2(
        qmem_out[12]), .Z(mac_in[12]) );
  AO22D0 U90 ( .A1(mac_in_mux_sel), .A2(kmem_out[11]), .B1(n26), .B2(
        qmem_out[11]), .Z(mac_in[11]) );
  AO22D0 U91 ( .A1(mac_in_mux_sel), .A2(kmem_out[10]), .B1(n26), .B2(
        qmem_out[10]), .Z(mac_in[10]) );
  AO22D0 U92 ( .A1(mac_in_mux_sel), .A2(kmem_out[9]), .B1(n26), .B2(
        qmem_out[9]), .Z(mac_in[9]) );
  AO22D0 U93 ( .A1(mac_in_mux_sel), .A2(kmem_out[8]), .B1(n26), .B2(
        qmem_out[8]), .Z(mac_in[8]) );
  AO22D0 U94 ( .A1(mac_in_mux_sel), .A2(kmem_out[7]), .B1(n26), .B2(
        qmem_out[7]), .Z(mac_in[7]) );
  AO22D0 U95 ( .A1(mac_in_mux_sel), .A2(kmem_out[6]), .B1(n26), .B2(
        qmem_out[6]), .Z(mac_in[6]) );
  AO22D0 U96 ( .A1(mac_in_mux_sel), .A2(kmem_out[5]), .B1(n26), .B2(
        qmem_out[5]), .Z(mac_in[5]) );
  AO22D0 U97 ( .A1(mac_in_mux_sel), .A2(kmem_out[4]), .B1(n26), .B2(
        qmem_out[4]), .Z(mac_in[4]) );
  AO22D0 U98 ( .A1(mac_in_mux_sel), .A2(kmem_out[3]), .B1(n26), .B2(
        qmem_out[3]), .Z(mac_in[3]) );
  AO22D0 U99 ( .A1(mac_in_mux_sel), .A2(kmem_out[2]), .B1(n26), .B2(
        qmem_out[2]), .Z(mac_in[2]) );
  AO22D0 U100 ( .A1(mac_in_mux_sel), .A2(kmem_out[1]), .B1(n26), .B2(
        qmem_out[1]), .Z(mac_in[1]) );
  AO22D0 U101 ( .A1(mac_in_mux_sel), .A2(kmem_out[0]), .B1(n26), .B2(
        qmem_out[0]), .Z(mac_in[0]) );
  AO22D0 U102 ( .A1(inst[18]), .A2(ofifo_out[159]), .B1(n51), .B2(sfp_out[159]), .Z(pmem_mux_in[159]) );
  AO22D0 U103 ( .A1(inst[18]), .A2(ofifo_out[158]), .B1(n27), .B2(sfp_out[158]), .Z(pmem_mux_in[158]) );
  AO22D0 U104 ( .A1(inst[18]), .A2(ofifo_out[157]), .B1(n52), .B2(sfp_out[157]), .Z(pmem_mux_in[157]) );
  AO22D0 U105 ( .A1(inst[18]), .A2(ofifo_out[156]), .B1(n51), .B2(sfp_out[156]), .Z(pmem_mux_in[156]) );
  AO22D0 U106 ( .A1(inst[18]), .A2(ofifo_out[155]), .B1(n27), .B2(sfp_out[155]), .Z(pmem_mux_in[155]) );
  AO22D0 U107 ( .A1(inst[18]), .A2(ofifo_out[154]), .B1(n52), .B2(sfp_out[154]), .Z(pmem_mux_in[154]) );
  AO22D0 U108 ( .A1(inst[18]), .A2(ofifo_out[153]), .B1(n51), .B2(sfp_out[153]), .Z(pmem_mux_in[153]) );
  AO22D0 U109 ( .A1(inst[18]), .A2(ofifo_out[152]), .B1(n27), .B2(sfp_out[152]), .Z(pmem_mux_in[152]) );
  AO22D0 U110 ( .A1(inst[18]), .A2(ofifo_out[151]), .B1(n52), .B2(sfp_out[151]), .Z(pmem_mux_in[151]) );
  AO22D0 U111 ( .A1(inst[18]), .A2(ofifo_out[150]), .B1(n51), .B2(sfp_out[150]), .Z(pmem_mux_in[150]) );
  AO22D0 U112 ( .A1(inst[18]), .A2(ofifo_out[149]), .B1(n27), .B2(sfp_out[149]), .Z(pmem_mux_in[149]) );
  AO22D0 U113 ( .A1(inst[18]), .A2(ofifo_out[148]), .B1(n51), .B2(sfp_out[148]), .Z(pmem_mux_in[148]) );
  AO22D0 U114 ( .A1(inst[18]), .A2(ofifo_out[147]), .B1(n27), .B2(sfp_out[147]), .Z(pmem_mux_in[147]) );
  AO22D0 U115 ( .A1(inst[18]), .A2(ofifo_out[146]), .B1(n52), .B2(sfp_out[146]), .Z(pmem_mux_in[146]) );
  AO22D0 U116 ( .A1(inst[18]), .A2(ofifo_out[145]), .B1(n27), .B2(sfp_out[145]), .Z(pmem_mux_in[145]) );
  AO22D0 U117 ( .A1(inst[18]), .A2(ofifo_out[144]), .B1(n51), .B2(sfp_out[144]), .Z(pmem_mux_in[144]) );
  AO22D0 U118 ( .A1(inst[18]), .A2(ofifo_out[143]), .B1(n52), .B2(sfp_out[143]), .Z(pmem_mux_in[143]) );
  AO22D0 U119 ( .A1(inst[18]), .A2(ofifo_out[142]), .B1(n52), .B2(sfp_out[142]), .Z(pmem_mux_in[142]) );
  AO22D0 U120 ( .A1(inst[18]), .A2(ofifo_out[141]), .B1(n27), .B2(sfp_out[141]), .Z(pmem_mux_in[141]) );
  AO22D0 U121 ( .A1(inst[18]), .A2(ofifo_out[140]), .B1(n51), .B2(sfp_out[140]), .Z(pmem_mux_in[140]) );
  AO22D0 U122 ( .A1(inst[18]), .A2(ofifo_out[139]), .B1(n51), .B2(sfp_out[139]), .Z(pmem_mux_in[139]) );
  AO22D0 U123 ( .A1(inst[18]), .A2(ofifo_out[138]), .B1(n52), .B2(sfp_out[138]), .Z(pmem_mux_in[138]) );
  AO22D0 U124 ( .A1(inst[18]), .A2(ofifo_out[137]), .B1(n27), .B2(sfp_out[137]), .Z(pmem_mux_in[137]) );
  AO22D0 U125 ( .A1(inst[18]), .A2(ofifo_out[136]), .B1(n51), .B2(sfp_out[136]), .Z(pmem_mux_in[136]) );
  AO22D0 U126 ( .A1(inst[18]), .A2(ofifo_out[135]), .B1(n52), .B2(sfp_out[135]), .Z(pmem_mux_in[135]) );
  AO22D0 U127 ( .A1(inst[18]), .A2(ofifo_out[134]), .B1(n52), .B2(sfp_out[134]), .Z(pmem_mux_in[134]) );
  AO22D0 U128 ( .A1(inst[18]), .A2(ofifo_out[133]), .B1(n27), .B2(sfp_out[133]), .Z(pmem_mux_in[133]) );
  AO22D0 U129 ( .A1(inst[18]), .A2(ofifo_out[132]), .B1(n51), .B2(sfp_out[132]), .Z(pmem_mux_in[132]) );
  AO22D0 U130 ( .A1(inst[18]), .A2(ofifo_out[131]), .B1(n52), .B2(sfp_out[131]), .Z(pmem_mux_in[131]) );
  AO22D0 U131 ( .A1(inst[18]), .A2(ofifo_out[130]), .B1(n51), .B2(sfp_out[130]), .Z(pmem_mux_in[130]) );
  AO22D0 U132 ( .A1(inst[18]), .A2(ofifo_out[129]), .B1(n51), .B2(sfp_out[129]), .Z(pmem_mux_in[129]) );
  AO22D0 U133 ( .A1(inst[18]), .A2(ofifo_out[128]), .B1(n52), .B2(sfp_out[128]), .Z(pmem_mux_in[128]) );
  AO22D0 U134 ( .A1(inst[18]), .A2(ofifo_out[127]), .B1(n27), .B2(sfp_out[127]), .Z(pmem_mux_in[127]) );
  AO22D0 U135 ( .A1(inst[18]), .A2(ofifo_out[126]), .B1(n51), .B2(sfp_out[126]), .Z(pmem_mux_in[126]) );
  AO22D0 U136 ( .A1(inst[18]), .A2(ofifo_out[125]), .B1(n27), .B2(sfp_out[125]), .Z(pmem_mux_in[125]) );
  AO22D0 U137 ( .A1(inst[18]), .A2(ofifo_out[124]), .B1(n27), .B2(sfp_out[124]), .Z(pmem_mux_in[124]) );
  AO22D0 U138 ( .A1(inst[18]), .A2(ofifo_out[123]), .B1(n27), .B2(sfp_out[123]), .Z(pmem_mux_in[123]) );
  AO22D0 U139 ( .A1(inst[18]), .A2(ofifo_out[122]), .B1(n52), .B2(sfp_out[122]), .Z(pmem_mux_in[122]) );
  AO22D0 U140 ( .A1(inst[18]), .A2(ofifo_out[121]), .B1(n52), .B2(sfp_out[121]), .Z(pmem_mux_in[121]) );
  AO22D0 U141 ( .A1(inst[18]), .A2(ofifo_out[120]), .B1(n27), .B2(sfp_out[120]), .Z(pmem_mux_in[120]) );
  AO22D0 U142 ( .A1(inst[18]), .A2(ofifo_out[119]), .B1(n51), .B2(sfp_out[119]), .Z(pmem_mux_in[119]) );
  AO22D0 U143 ( .A1(inst[18]), .A2(ofifo_out[118]), .B1(n52), .B2(sfp_out[118]), .Z(pmem_mux_in[118]) );
  AO22D0 U144 ( .A1(inst[18]), .A2(ofifo_out[117]), .B1(n51), .B2(sfp_out[117]), .Z(pmem_mux_in[117]) );
  AO22D0 U145 ( .A1(inst[18]), .A2(ofifo_out[116]), .B1(n52), .B2(sfp_out[116]), .Z(pmem_mux_in[116]) );
  AO22D0 U146 ( .A1(inst[18]), .A2(ofifo_out[115]), .B1(n27), .B2(sfp_out[115]), .Z(pmem_mux_in[115]) );
  AO22D0 U147 ( .A1(inst[18]), .A2(ofifo_out[114]), .B1(n51), .B2(sfp_out[114]), .Z(pmem_mux_in[114]) );
  AO22D0 U148 ( .A1(inst[18]), .A2(ofifo_out[113]), .B1(n27), .B2(sfp_out[113]), .Z(pmem_mux_in[113]) );
  AO22D0 U149 ( .A1(inst[18]), .A2(ofifo_out[112]), .B1(n27), .B2(sfp_out[112]), .Z(pmem_mux_in[112]) );
  AO22D0 U150 ( .A1(inst[18]), .A2(ofifo_out[111]), .B1(n51), .B2(sfp_out[111]), .Z(pmem_mux_in[111]) );
  AO22D0 U151 ( .A1(inst[18]), .A2(ofifo_out[110]), .B1(n52), .B2(sfp_out[110]), .Z(pmem_mux_in[110]) );
  AO22D0 U152 ( .A1(inst[18]), .A2(ofifo_out[109]), .B1(n52), .B2(sfp_out[109]), .Z(pmem_mux_in[109]) );
  AO22D0 U153 ( .A1(inst[18]), .A2(ofifo_out[108]), .B1(n52), .B2(sfp_out[108]), .Z(pmem_mux_in[108]) );
  AO22D0 U154 ( .A1(inst[18]), .A2(ofifo_out[107]), .B1(n27), .B2(sfp_out[107]), .Z(pmem_mux_in[107]) );
  AO22D0 U155 ( .A1(inst[18]), .A2(ofifo_out[106]), .B1(n51), .B2(sfp_out[106]), .Z(pmem_mux_in[106]) );
  AO22D0 U156 ( .A1(inst[18]), .A2(ofifo_out[105]), .B1(n51), .B2(sfp_out[105]), .Z(pmem_mux_in[105]) );
  AO22D0 U157 ( .A1(inst[18]), .A2(ofifo_out[104]), .B1(n27), .B2(sfp_out[104]), .Z(pmem_mux_in[104]) );
  AO22D0 U158 ( .A1(inst[18]), .A2(ofifo_out[103]), .B1(n51), .B2(sfp_out[103]), .Z(pmem_mux_in[103]) );
  AO22D0 U159 ( .A1(inst[18]), .A2(ofifo_out[102]), .B1(n27), .B2(sfp_out[102]), .Z(pmem_mux_in[102]) );
  AO22D0 U160 ( .A1(inst[18]), .A2(ofifo_out[101]), .B1(n52), .B2(sfp_out[101]), .Z(pmem_mux_in[101]) );
  AO22D0 U161 ( .A1(inst[18]), .A2(ofifo_out[100]), .B1(n27), .B2(sfp_out[100]), .Z(pmem_mux_in[100]) );
  AO22D0 U162 ( .A1(inst[18]), .A2(ofifo_out[99]), .B1(n52), .B2(sfp_out[99]), 
        .Z(pmem_mux_in[99]) );
  AO22D0 U163 ( .A1(inst[18]), .A2(ofifo_out[98]), .B1(n52), .B2(sfp_out[98]), 
        .Z(pmem_mux_in[98]) );
  AO22D0 U164 ( .A1(inst[18]), .A2(ofifo_out[97]), .B1(n51), .B2(sfp_out[97]), 
        .Z(pmem_mux_in[97]) );
  AO22D0 U165 ( .A1(inst[18]), .A2(ofifo_out[96]), .B1(n27), .B2(sfp_out[96]), 
        .Z(pmem_mux_in[96]) );
  AO22D0 U166 ( .A1(inst[18]), .A2(ofifo_out[95]), .B1(n27), .B2(sfp_out[95]), 
        .Z(pmem_mux_in[95]) );
  AO22D0 U167 ( .A1(inst[18]), .A2(ofifo_out[94]), .B1(n52), .B2(sfp_out[94]), 
        .Z(pmem_mux_in[94]) );
  AO22D0 U168 ( .A1(inst[18]), .A2(ofifo_out[93]), .B1(n51), .B2(sfp_out[93]), 
        .Z(pmem_mux_in[93]) );
  AO22D0 U169 ( .A1(inst[18]), .A2(ofifo_out[92]), .B1(n51), .B2(sfp_out[92]), 
        .Z(pmem_mux_in[92]) );
  AO22D0 U170 ( .A1(inst[18]), .A2(ofifo_out[91]), .B1(n27), .B2(sfp_out[91]), 
        .Z(pmem_mux_in[91]) );
  AO22D0 U171 ( .A1(inst[18]), .A2(ofifo_out[90]), .B1(n52), .B2(sfp_out[90]), 
        .Z(pmem_mux_in[90]) );
  AO22D0 U172 ( .A1(inst[18]), .A2(ofifo_out[89]), .B1(n52), .B2(sfp_out[89]), 
        .Z(pmem_mux_in[89]) );
  AO22D0 U173 ( .A1(inst[18]), .A2(ofifo_out[88]), .B1(n52), .B2(sfp_out[88]), 
        .Z(pmem_mux_in[88]) );
  AO22D0 U174 ( .A1(inst[18]), .A2(ofifo_out[87]), .B1(n52), .B2(sfp_out[87]), 
        .Z(pmem_mux_in[87]) );
  AO22D0 U175 ( .A1(inst[18]), .A2(ofifo_out[86]), .B1(n51), .B2(sfp_out[86]), 
        .Z(pmem_mux_in[86]) );
  AO22D0 U176 ( .A1(inst[18]), .A2(ofifo_out[85]), .B1(n52), .B2(sfp_out[85]), 
        .Z(pmem_mux_in[85]) );
  AO22D0 U177 ( .A1(inst[18]), .A2(ofifo_out[84]), .B1(n52), .B2(sfp_out[84]), 
        .Z(pmem_mux_in[84]) );
  AO22D0 U178 ( .A1(inst[18]), .A2(ofifo_out[83]), .B1(n27), .B2(sfp_out[83]), 
        .Z(pmem_mux_in[83]) );
  AO22D0 U179 ( .A1(inst[18]), .A2(ofifo_out[82]), .B1(n27), .B2(sfp_out[82]), 
        .Z(pmem_mux_in[82]) );
  AO22D0 U180 ( .A1(inst[18]), .A2(ofifo_out[81]), .B1(n52), .B2(sfp_out[81]), 
        .Z(pmem_mux_in[81]) );
  AO22D0 U181 ( .A1(inst[18]), .A2(ofifo_out[80]), .B1(n27), .B2(sfp_out[80]), 
        .Z(pmem_mux_in[80]) );
  AO22D0 U182 ( .A1(inst[18]), .A2(ofifo_out[79]), .B1(n51), .B2(sfp_out[79]), 
        .Z(pmem_mux_in[79]) );
  AO22D0 U183 ( .A1(inst[18]), .A2(ofifo_out[78]), .B1(n52), .B2(sfp_out[78]), 
        .Z(pmem_mux_in[78]) );
  AO22D0 U184 ( .A1(inst[18]), .A2(ofifo_out[77]), .B1(n51), .B2(sfp_out[77]), 
        .Z(pmem_mux_in[77]) );
  AO22D0 U185 ( .A1(inst[18]), .A2(ofifo_out[76]), .B1(n51), .B2(sfp_out[76]), 
        .Z(pmem_mux_in[76]) );
  AO22D0 U186 ( .A1(inst[18]), .A2(ofifo_out[75]), .B1(n27), .B2(sfp_out[75]), 
        .Z(pmem_mux_in[75]) );
  AO22D0 U187 ( .A1(inst[18]), .A2(ofifo_out[74]), .B1(n27), .B2(sfp_out[74]), 
        .Z(pmem_mux_in[74]) );
  AO22D0 U188 ( .A1(inst[18]), .A2(ofifo_out[73]), .B1(n51), .B2(sfp_out[73]), 
        .Z(pmem_mux_in[73]) );
  AO22D0 U189 ( .A1(inst[18]), .A2(ofifo_out[72]), .B1(n52), .B2(sfp_out[72]), 
        .Z(pmem_mux_in[72]) );
  AO22D0 U190 ( .A1(inst[18]), .A2(ofifo_out[71]), .B1(n27), .B2(sfp_out[71]), 
        .Z(pmem_mux_in[71]) );
  AO22D0 U191 ( .A1(inst[18]), .A2(ofifo_out[70]), .B1(n51), .B2(sfp_out[70]), 
        .Z(pmem_mux_in[70]) );
  AO22D0 U192 ( .A1(inst[18]), .A2(ofifo_out[69]), .B1(n27), .B2(sfp_out[69]), 
        .Z(pmem_mux_in[69]) );
  AO22D0 U193 ( .A1(inst[18]), .A2(ofifo_out[68]), .B1(n51), .B2(sfp_out[68]), 
        .Z(pmem_mux_in[68]) );
  AO22D0 U194 ( .A1(inst[18]), .A2(ofifo_out[67]), .B1(n51), .B2(sfp_out[67]), 
        .Z(pmem_mux_in[67]) );
  AO22D0 U195 ( .A1(inst[18]), .A2(ofifo_out[66]), .B1(n51), .B2(sfp_out[66]), 
        .Z(pmem_mux_in[66]) );
  AO22D0 U196 ( .A1(inst[18]), .A2(ofifo_out[65]), .B1(n27), .B2(sfp_out[65]), 
        .Z(pmem_mux_in[65]) );
  AO22D0 U197 ( .A1(inst[18]), .A2(ofifo_out[64]), .B1(n52), .B2(sfp_out[64]), 
        .Z(pmem_mux_in[64]) );
  AO22D0 U198 ( .A1(inst[18]), .A2(ofifo_out[63]), .B1(n52), .B2(sfp_out[63]), 
        .Z(pmem_mux_in[63]) );
  AO22D0 U199 ( .A1(inst[18]), .A2(ofifo_out[62]), .B1(n51), .B2(sfp_out[62]), 
        .Z(pmem_mux_in[62]) );
  AO22D0 U200 ( .A1(inst[18]), .A2(ofifo_out[61]), .B1(n52), .B2(sfp_out[61]), 
        .Z(pmem_mux_in[61]) );
  AO22D0 U201 ( .A1(inst[18]), .A2(ofifo_out[60]), .B1(n27), .B2(sfp_out[60]), 
        .Z(pmem_mux_in[60]) );
  AO22D0 U202 ( .A1(inst[18]), .A2(ofifo_out[59]), .B1(n51), .B2(sfp_out[59]), 
        .Z(pmem_mux_in[59]) );
  AO22D0 U203 ( .A1(inst[18]), .A2(ofifo_out[58]), .B1(n27), .B2(sfp_out[58]), 
        .Z(pmem_mux_in[58]) );
  AO22D0 U204 ( .A1(inst[18]), .A2(ofifo_out[57]), .B1(n27), .B2(sfp_out[57]), 
        .Z(pmem_mux_in[57]) );
  AO22D0 U205 ( .A1(inst[18]), .A2(ofifo_out[56]), .B1(n52), .B2(sfp_out[56]), 
        .Z(pmem_mux_in[56]) );
  AO22D0 U206 ( .A1(inst[18]), .A2(ofifo_out[55]), .B1(n52), .B2(sfp_out[55]), 
        .Z(pmem_mux_in[55]) );
  AO22D0 U207 ( .A1(inst[18]), .A2(ofifo_out[54]), .B1(n52), .B2(sfp_out[54]), 
        .Z(pmem_mux_in[54]) );
  AO22D0 U208 ( .A1(inst[18]), .A2(ofifo_out[53]), .B1(n27), .B2(sfp_out[53]), 
        .Z(pmem_mux_in[53]) );
  AO22D0 U209 ( .A1(inst[18]), .A2(ofifo_out[52]), .B1(n52), .B2(sfp_out[52]), 
        .Z(pmem_mux_in[52]) );
  AO22D0 U210 ( .A1(inst[18]), .A2(ofifo_out[51]), .B1(n52), .B2(sfp_out[51]), 
        .Z(pmem_mux_in[51]) );
  AO22D0 U211 ( .A1(inst[18]), .A2(ofifo_out[50]), .B1(n27), .B2(sfp_out[50]), 
        .Z(pmem_mux_in[50]) );
  AO22D0 U212 ( .A1(inst[18]), .A2(ofifo_out[49]), .B1(n51), .B2(sfp_out[49]), 
        .Z(pmem_mux_in[49]) );
  AO22D0 U213 ( .A1(inst[18]), .A2(ofifo_out[48]), .B1(n51), .B2(sfp_out[48]), 
        .Z(pmem_mux_in[48]) );
  AO22D0 U214 ( .A1(inst[18]), .A2(ofifo_out[47]), .B1(n51), .B2(sfp_out[47]), 
        .Z(pmem_mux_in[47]) );
  AO22D0 U215 ( .A1(inst[18]), .A2(ofifo_out[46]), .B1(n51), .B2(sfp_out[46]), 
        .Z(pmem_mux_in[46]) );
  AO22D0 U216 ( .A1(inst[18]), .A2(ofifo_out[45]), .B1(n27), .B2(sfp_out[45]), 
        .Z(pmem_mux_in[45]) );
  AO22D0 U217 ( .A1(inst[18]), .A2(ofifo_out[44]), .B1(n27), .B2(sfp_out[44]), 
        .Z(pmem_mux_in[44]) );
  AO22D0 U218 ( .A1(inst[18]), .A2(ofifo_out[43]), .B1(n51), .B2(sfp_out[43]), 
        .Z(pmem_mux_in[43]) );
  AO22D0 U219 ( .A1(inst[18]), .A2(ofifo_out[42]), .B1(n27), .B2(sfp_out[42]), 
        .Z(pmem_mux_in[42]) );
  AO22D0 U220 ( .A1(inst[18]), .A2(ofifo_out[41]), .B1(n51), .B2(sfp_out[41]), 
        .Z(pmem_mux_in[41]) );
  AO22D0 U221 ( .A1(inst[18]), .A2(ofifo_out[40]), .B1(n27), .B2(sfp_out[40]), 
        .Z(pmem_mux_in[40]) );
  AO22D0 U222 ( .A1(inst[18]), .A2(ofifo_out[39]), .B1(n51), .B2(sfp_out[39]), 
        .Z(pmem_mux_in[39]) );
  AO22D0 U223 ( .A1(inst[18]), .A2(ofifo_out[38]), .B1(n51), .B2(sfp_out[38]), 
        .Z(pmem_mux_in[38]) );
  AO22D0 U224 ( .A1(inst[18]), .A2(ofifo_out[37]), .B1(n51), .B2(sfp_out[37]), 
        .Z(pmem_mux_in[37]) );
  AO22D0 U225 ( .A1(inst[18]), .A2(ofifo_out[36]), .B1(n51), .B2(sfp_out[36]), 
        .Z(pmem_mux_in[36]) );
  AO22D0 U226 ( .A1(inst[18]), .A2(ofifo_out[35]), .B1(n51), .B2(sfp_out[35]), 
        .Z(pmem_mux_in[35]) );
  AO22D0 U227 ( .A1(inst[18]), .A2(ofifo_out[34]), .B1(n51), .B2(sfp_out[34]), 
        .Z(pmem_mux_in[34]) );
  AO22D0 U228 ( .A1(inst[18]), .A2(ofifo_out[33]), .B1(n51), .B2(sfp_out[33]), 
        .Z(pmem_mux_in[33]) );
  AO22D0 U229 ( .A1(inst[18]), .A2(ofifo_out[32]), .B1(n51), .B2(sfp_out[32]), 
        .Z(pmem_mux_in[32]) );
  AO22D0 U230 ( .A1(inst[18]), .A2(ofifo_out[31]), .B1(n51), .B2(sfp_out[31]), 
        .Z(pmem_mux_in[31]) );
  AO22D0 U231 ( .A1(inst[18]), .A2(ofifo_out[30]), .B1(n51), .B2(sfp_out[30]), 
        .Z(pmem_mux_in[30]) );
  AO22D0 U232 ( .A1(inst[18]), .A2(ofifo_out[29]), .B1(n51), .B2(sfp_out[29]), 
        .Z(pmem_mux_in[29]) );
  AO22D0 U233 ( .A1(inst[18]), .A2(ofifo_out[28]), .B1(n51), .B2(sfp_out[28]), 
        .Z(pmem_mux_in[28]) );
  AO22D0 U234 ( .A1(inst[18]), .A2(ofifo_out[27]), .B1(n52), .B2(sfp_out[27]), 
        .Z(pmem_mux_in[27]) );
  AO22D0 U235 ( .A1(inst[18]), .A2(ofifo_out[26]), .B1(n27), .B2(sfp_out[26]), 
        .Z(pmem_mux_in[26]) );
  AO22D0 U236 ( .A1(inst[18]), .A2(ofifo_out[25]), .B1(n51), .B2(sfp_out[25]), 
        .Z(pmem_mux_in[25]) );
  AO22D0 U237 ( .A1(inst[18]), .A2(ofifo_out[24]), .B1(n27), .B2(sfp_out[24]), 
        .Z(pmem_mux_in[24]) );
  AO22D0 U238 ( .A1(inst[18]), .A2(ofifo_out[23]), .B1(n27), .B2(sfp_out[23]), 
        .Z(pmem_mux_in[23]) );
  AO22D0 U239 ( .A1(inst[18]), .A2(ofifo_out[22]), .B1(n27), .B2(sfp_out[22]), 
        .Z(pmem_mux_in[22]) );
  AO22D0 U240 ( .A1(inst[18]), .A2(ofifo_out[21]), .B1(n27), .B2(sfp_out[21]), 
        .Z(pmem_mux_in[21]) );
  AO22D0 U241 ( .A1(inst[18]), .A2(ofifo_out[20]), .B1(n27), .B2(sfp_out[20]), 
        .Z(pmem_mux_in[20]) );
  AO22D0 U242 ( .A1(inst[18]), .A2(ofifo_out[19]), .B1(n51), .B2(sfp_out[19]), 
        .Z(pmem_mux_in[19]) );
  AO22D0 U243 ( .A1(inst[18]), .A2(ofifo_out[18]), .B1(n27), .B2(sfp_out[18]), 
        .Z(pmem_mux_in[18]) );
  AO22D0 U244 ( .A1(inst[18]), .A2(ofifo_out[17]), .B1(n27), .B2(sfp_out[17]), 
        .Z(pmem_mux_in[17]) );
  AO22D0 U245 ( .A1(inst[18]), .A2(ofifo_out[16]), .B1(n27), .B2(sfp_out[16]), 
        .Z(pmem_mux_in[16]) );
  AO22D0 U246 ( .A1(inst[18]), .A2(ofifo_out[15]), .B1(n52), .B2(sfp_out[15]), 
        .Z(pmem_mux_in[15]) );
  AO22D0 U247 ( .A1(inst[18]), .A2(ofifo_out[14]), .B1(n27), .B2(sfp_out[14]), 
        .Z(pmem_mux_in[14]) );
  AO22D0 U248 ( .A1(inst[18]), .A2(ofifo_out[13]), .B1(n52), .B2(sfp_out[13]), 
        .Z(pmem_mux_in[13]) );
  AO22D0 U249 ( .A1(inst[18]), .A2(ofifo_out[12]), .B1(n27), .B2(sfp_out[12]), 
        .Z(pmem_mux_in[12]) );
  AO22D0 U250 ( .A1(inst[18]), .A2(ofifo_out[11]), .B1(n52), .B2(sfp_out[11]), 
        .Z(pmem_mux_in[11]) );
  AO22D0 U251 ( .A1(inst[18]), .A2(ofifo_out[10]), .B1(n27), .B2(sfp_out[10]), 
        .Z(pmem_mux_in[10]) );
  AO22D0 U252 ( .A1(inst[18]), .A2(ofifo_out[9]), .B1(n52), .B2(sfp_out[9]), 
        .Z(pmem_mux_in[9]) );
  AO22D0 U253 ( .A1(inst[18]), .A2(ofifo_out[8]), .B1(n52), .B2(sfp_out[8]), 
        .Z(pmem_mux_in[8]) );
  AO22D0 U254 ( .A1(inst[18]), .A2(ofifo_out[7]), .B1(n52), .B2(sfp_out[7]), 
        .Z(pmem_mux_in[7]) );
  AO22D0 U255 ( .A1(inst[18]), .A2(ofifo_out[6]), .B1(n52), .B2(sfp_out[6]), 
        .Z(pmem_mux_in[6]) );
  AO22D0 U256 ( .A1(inst[18]), .A2(ofifo_out[5]), .B1(n52), .B2(sfp_out[5]), 
        .Z(pmem_mux_in[5]) );
  AO22D0 U257 ( .A1(inst[18]), .A2(ofifo_out[4]), .B1(n52), .B2(sfp_out[4]), 
        .Z(pmem_mux_in[4]) );
  AO22D0 U258 ( .A1(inst[18]), .A2(ofifo_out[3]), .B1(n52), .B2(sfp_out[3]), 
        .Z(pmem_mux_in[3]) );
  AO22D0 U259 ( .A1(inst[18]), .A2(ofifo_out[2]), .B1(n52), .B2(sfp_out[2]), 
        .Z(pmem_mux_in[2]) );
  AO22D0 U260 ( .A1(inst[18]), .A2(ofifo_out[1]), .B1(n52), .B2(sfp_out[1]), 
        .Z(pmem_mux_in[1]) );
  AO22D0 U261 ( .A1(inst[18]), .A2(ofifo_out[0]), .B1(n52), .B2(sfp_out[0]), 
        .Z(pmem_mux_in[0]) );
  DFCND1 mac_in_mux_sel_reg ( .D(inst[6]), .CP(clk), .CDN(n25), .Q(
        mac_in_mux_sel), .QN(n26) );
  INVD0 U27 ( .I(reset), .ZN(n25) );
  INVD1 U28 ( .I(inst[18]), .ZN(n27) );
  BUFFD1 U29 ( .I(n27), .Z(n52) );
  BUFFD1 U30 ( .I(n52), .Z(n51) );
  OR2D0 U31 ( .A1(inst[0]), .A2(inst[1]), .Z(N8) );
  OR2D0 U262 ( .A1(inst[2]), .A2(inst[3]), .Z(N7) );
  OR2D0 U263 ( .A1(inst[4]), .A2(inst[5]), .Z(N6) );
endmodule


module fullchip ( clk, reset, inst, out, core0_mem_in );
  input [19:0] inst;
  output [159:0] out;
  input [63:0] core0_mem_in;
  input clk, reset;
  wire   SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2,
         SYNOPSYS_UNCONNECTED_3, SYNOPSYS_UNCONNECTED_4,
         SYNOPSYS_UNCONNECTED_5, SYNOPSYS_UNCONNECTED_6,
         SYNOPSYS_UNCONNECTED_7, SYNOPSYS_UNCONNECTED_8,
         SYNOPSYS_UNCONNECTED_9, SYNOPSYS_UNCONNECTED_10,
         SYNOPSYS_UNCONNECTED_11, SYNOPSYS_UNCONNECTED_12,
         SYNOPSYS_UNCONNECTED_13, SYNOPSYS_UNCONNECTED_14,
         SYNOPSYS_UNCONNECTED_15, SYNOPSYS_UNCONNECTED_16,
         SYNOPSYS_UNCONNECTED_17, SYNOPSYS_UNCONNECTED_18,
         SYNOPSYS_UNCONNECTED_19, SYNOPSYS_UNCONNECTED_20,
         SYNOPSYS_UNCONNECTED_21, SYNOPSYS_UNCONNECTED_22,
         SYNOPSYS_UNCONNECTED_23, SYNOPSYS_UNCONNECTED_24;
  tri   clk;
  tri   reset;
  tri   [159:0] out;
  tri   [63:0] core0_mem_in;
  tri   core0_clk;

  buffer clkbuf_core0 ( .in_clk(clk), .out_clk(core0_clk) );
  core_col8_bw8_bw_psum20_pr8 core_instance0 ( .clk(core0_clk), .reset(reset), 
        .mem_in(core0_mem_in), .sum_in({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}), .inst({1'b0, inst[18:0]}), 
        .sum_out({SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2, 
        SYNOPSYS_UNCONNECTED_3, SYNOPSYS_UNCONNECTED_4, SYNOPSYS_UNCONNECTED_5, 
        SYNOPSYS_UNCONNECTED_6, SYNOPSYS_UNCONNECTED_7, SYNOPSYS_UNCONNECTED_8, 
        SYNOPSYS_UNCONNECTED_9, SYNOPSYS_UNCONNECTED_10, 
        SYNOPSYS_UNCONNECTED_11, SYNOPSYS_UNCONNECTED_12, 
        SYNOPSYS_UNCONNECTED_13, SYNOPSYS_UNCONNECTED_14, 
        SYNOPSYS_UNCONNECTED_15, SYNOPSYS_UNCONNECTED_16, 
        SYNOPSYS_UNCONNECTED_17, SYNOPSYS_UNCONNECTED_18, 
        SYNOPSYS_UNCONNECTED_19, SYNOPSYS_UNCONNECTED_20, 
        SYNOPSYS_UNCONNECTED_21, SYNOPSYS_UNCONNECTED_22, 
        SYNOPSYS_UNCONNECTED_23, SYNOPSYS_UNCONNECTED_24}), .out(out) );
endmodule

