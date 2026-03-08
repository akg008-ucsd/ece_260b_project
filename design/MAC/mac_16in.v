// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission

`ifdef CLK_GATE
module mac_16in (out, a, b, zero, clk, reset);
`else
module mac_16in (out, a, b, clk, reset);
`endif

parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter pr = 8; // parallel factor: number of inputs = 8

output reg [bw_psum-1:0] out;
input  [pr*bw-1:0] a;
input  [pr*bw-1:0] b;
input clk, reset;
`ifdef CLK_GATE
input [pr-1:0] zero;
`endif

genvar i,j,k;

wire [2*bw-1:0] product      [pr-1:0];

`ifndef MULT_PIPE_EN

// -----------------------------------------------------------------------
// Non-pipelined multiplier path
// -----------------------------------------------------------------------
reg  [2*bw-1:0] product_pipe [pr-1:0];

generate
    for (i=0; i<pr; i=i+1) begin : compute_prod
        // -------------------------------------------------------------------
        // Gating priority (all four combinations of CLK_GATE / OPR_ISO):
        //   CLK_GATE + OPR_ISO : gate on zero[i] OR either input slice == 0
        //   CLK_GATE only      : gate on zero[i] external signal
        //   OPR_ISO only       : gate when either input slice == 0 (auto)
        //   neither            : always compute (original behaviour)
        // -------------------------------------------------------------------
        `ifdef CLK_GATE
            `ifdef OPR_ISO
                assign product[i] = (zero[i] ||
                                     (a[bw*(i+1)-1:bw*i] == {bw{1'b0}}) ||
                                     (b[bw*(i+1)-1:bw*i] == {bw{1'b0}}))
                    ? {2*bw{1'b0}}
                    : {{(bw){a[bw*(i+1)-1]}}, a[bw*(i+1)-1:bw*i]}
                    * {{(bw){b[bw*(i+1)-1]}}, b[bw*(i+1)-1:bw*i]};
            `else
                assign product[i] = zero[i]
                    ? {2*bw{1'b0}}
                    : {{(bw){a[bw*(i+1)-1]}}, a[bw*(i+1)-1:bw*i]}
                    * {{(bw){b[bw*(i+1)-1]}}, b[bw*(i+1)-1:bw*i]};
            `endif
        `elsif OPR_ISO
            assign product[i] = ((a[bw*(i+1)-1:bw*i] == {bw{1'b0}}) ||
                                  (b[bw*(i+1)-1:bw*i] == {bw{1'b0}}))
                ? {2*bw{1'b0}}
                : {{(bw){a[bw*(i+1)-1]}}, a[bw*(i+1)-1:bw*i]}
                * {{(bw){b[bw*(i+1)-1]}}, b[bw*(i+1)-1:bw*i]};
        `else
            assign product[i] = {{(bw){a[bw*(i+1)-1]}}, a[bw*(i+1)-1:bw*i]}
                               * {{(bw){b[bw*(i+1)-1]}}, b[bw*(i+1)-1:bw*i]};
        `endif
    end
endgenerate

generate
    for (i=0; i<pr; i=i+1) begin : prod_pipeline
        always @(posedge clk or posedge reset) begin
            if (reset)
                product_pipe[i] <= {(2*bw){1'b0}};
            else
                product_pipe[i] <= product[i];
        end
    end
endgenerate

`else

// -----------------------------------------------------------------------
// Pipelined multiplier path (MULT_PIPE_EN)
// -----------------------------------------------------------------------
wire [(bw>>1)-1:0]        a_lo [pr-1:0];
wire signed [(bw>>1)-1:0] a_hi [pr-1:0];
wire [(bw>>1)-1:0]        b_lo [pr-1:0];
wire signed [(bw>>1)-1:0] b_hi [pr-1:0];

reg signed [bw-1:0]   pprod_ll [pr-1:0];
reg signed [bw-1:0]   pprod_lh [pr-1:0];
reg signed [bw-1:0]   pprod_hl [pr-1:0];
reg signed [bw-1:0]   pprod_hh [pr-1:0];

reg signed [2*bw-1:0] product_pipe [pr-1:0];

generate
    for (i=0; i<pr; i=i+1) begin : split_hi_lo
        assign a_lo[i] = a[(bw*i+(bw>>1))-1:bw*i];
        assign a_hi[i] = a[bw*(i+1)-1:bw*i+(bw>>1)];
        assign b_lo[i] = b[(bw*i+(bw>>1))-1:bw*i];
        assign b_hi[i] = b[bw*(i+1)-1:bw*i+(bw>>1)];
    end
endgenerate

generate
    for (j=0; j<pr; j=j+1) begin : stage_1
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                pprod_ll[j] <= {(bw){1'b0}};
                pprod_lh[j] <= {(bw){1'b0}};
                pprod_hl[j] <= {(bw){1'b0}};
                pprod_hh[j] <= {(bw){1'b0}};
            end
            else begin
                // -----------------------------------------------------------
                // OPR_ISO: if either full input slice is zero, all partial
                // products for that lane are zero ¿ skip the multiply tree.
                // CLK_GATE+OPR_ISO: gate on zero[j] OR zero input slice.
                // -----------------------------------------------------------
                `ifdef CLK_GATE
                    `ifdef OPR_ISO
                        if (zero[j] ||
                            (a[bw*(j+1)-1:bw*j] == {bw{1'b0}}) ||
                            (b[bw*(j+1)-1:bw*j] == {bw{1'b0}})) begin
                            pprod_ll[j] <= {(bw){1'b0}};
                            pprod_lh[j] <= {(bw){1'b0}};
                            pprod_hl[j] <= {(bw){1'b0}};
                            pprod_hh[j] <= {(bw){1'b0}};
                        end else begin
                            pprod_ll[j] <= a_lo[j] * b_lo[j];
                            pprod_lh[j] <= a_lo[j] * $signed({{(bw>>1){b_hi[j][(bw>>1)-1]}}, b_hi[j]});
                            pprod_hl[j] <= $signed({{(bw>>1){a_hi[j][(bw>>1)-1]}}, a_hi[j]}) * b_lo[j];
                            pprod_hh[j] <= $signed(a_hi[j]) * $signed(b_hi[j]);
                        end
                    `else
                        // CLK_GATE only
                        if (zero[j]) begin
                            pprod_ll[j] <= {(bw){1'b0}};
                            pprod_lh[j] <= {(bw){1'b0}};
                            pprod_hl[j] <= {(bw){1'b0}};
                            pprod_hh[j] <= {(bw){1'b0}};
                        end else begin
                            pprod_ll[j] <= a_lo[j] * b_lo[j];
                            pprod_lh[j] <= a_lo[j] * $signed({{(bw>>1){b_hi[j][(bw>>1)-1]}}, b_hi[j]});
                            pprod_hl[j] <= $signed({{(bw>>1){a_hi[j][(bw>>1)-1]}}, a_hi[j]}) * b_lo[j];
                            pprod_hh[j] <= $signed(a_hi[j]) * $signed(b_hi[j]);
                        end
                    `endif
                `elsif OPR_ISO
                    // OPR_ISO only
                    if ((a[bw*(j+1)-1:bw*j] == {bw{1'b0}}) ||
                        (b[bw*(j+1)-1:bw*j] == {bw{1'b0}})) begin
                        pprod_ll[j] <= {(bw){1'b0}};
                        pprod_lh[j] <= {(bw){1'b0}};
                        pprod_hl[j] <= {(bw){1'b0}};
                        pprod_hh[j] <= {(bw){1'b0}};
                    end else begin
                        pprod_ll[j] <= a_lo[j] * b_lo[j];
                        pprod_lh[j] <= a_lo[j] * $signed({{(bw>>1){b_hi[j][(bw>>1)-1]}}, b_hi[j]});
                        pprod_hl[j] <= $signed({{(bw>>1){a_hi[j][(bw>>1)-1]}}, a_hi[j]}) * b_lo[j];
                        pprod_hh[j] <= $signed(a_hi[j]) * $signed(b_hi[j]);
                    end
                `else
                    // Neither: original behaviour
                    pprod_ll[j] <= a_lo[j] * b_lo[j];
                    pprod_lh[j] <= a_lo[j] * $signed({{(bw>>1){b_hi[j][(bw>>1)-1]}}, b_hi[j]});
                    pprod_hl[j] <= $signed({{(bw>>1){a_hi[j][(bw>>1)-1]}}, a_hi[j]}) * b_lo[j];
                    pprod_hh[j] <= $signed(a_hi[j]) * $signed(b_hi[j]);
                `endif
            end
        end
    end
endgenerate

wire signed [2*bw-1:0] high_nib [pr-1:0];
wire signed [2*bw-1:0] mid_nib  [pr-1:0];
wire signed [2*bw-1:0] low_nib  [pr-1:0];

wire signed [2*bw-1:0] w_mid_nib    [pr-1:0];
wire                    mid_nib_sign [pr-1:0];

generate
    for (k=0; k<pr; k=k+1) begin : partial_add
        assign high_nib[k]      = pprod_hh[k] << bw;
        assign w_mid_nib[k]     = pprod_lh[k] + pprod_hl[k];
        assign mid_nib_sign[k]  = w_mid_nib[k][bw-1];
        assign mid_nib[k]       = {{4{mid_nib_sign[k]}}, w_mid_nib[k], 4'b0000};
        assign low_nib[k]       = {{8{1'b0}}, pprod_ll[k]};
    end
endgenerate

generate
    for (k=0; k<pr; k=k+1) begin : stage_2
        always @(posedge clk or posedge reset) begin
            if (reset)
                product_pipe[k] <= {(2*bw){1'b0}};
            else
                product_pipe[k] <= high_nib[k] + mid_nib[k] + low_nib[k];
        end
    end
endgenerate

`endif  // MULT_PIPE_EN

// -----------------------------------------------------------------------
// Accumulator: sign-extend each product_pipe lane and sum
// -----------------------------------------------------------------------
integer p;
always @(*) begin
    out = {(bw_psum){1'b0}};
    for (p=0; p<pr; p=p+1) begin
        out = out + {{4{product_pipe[p][2*bw-1]}}, product_pipe[p]};
    end
end

endmodule
