module fullchip #(
    parameter col = 8,
    parameter bw = 8,
    parameter bw_psum = 2*bw+4,
    parameter bw_psum_sum = bw_psum+4,
    parameter pr = 8
)(
    input  clk, 
    input  reset,
    input  [19:0] inst,
    output [bw_psum*col-1:0] out,
    input  [pr*bw-1:0] core0_mem_in 
);

    wire [bw_psum*col-1:0] out_core0;
    wire core0_clk;

    // FIFO interface (since EXPER is NOT defined)
    wire core0_fifo_ext_wr;
    wire core0_fifo_ext_rd;
    wire [bw_psum_sum-1:0] core0_sum_in;
    wire [bw_psum_sum-1:0] core0_sum_out;

    // Clock buffer
    buffer clkbuf_core0 (
        .in_clk(clk), 
        .out_clk(core0_clk)
    );

    // Single core ¿ output directly
    assign out = out_core0;

    // Since NOT DUAL_CORE, no async FIFO
    assign core0_sum_in = {bw_psum_sum{1'b0}};

    // Core instance (since GLS not defined ¿ parameterized)
    core #(
        .bw         (bw), 
        .bw_psum    (bw_psum), 
        .col        (col), 
        .pr         (pr)
    ) core_instance0 (
        .reset          (reset), 
        .clk            (core0_clk), 
        .mem_in         (core0_mem_in), 
        .fifo_ext_rd    (core0_fifo_ext_rd),
        .fifo_ext_wr    (core0_fifo_ext_wr),
        .sum_in         (core0_sum_in),
        .sum_out        (core0_sum_out),
        .out            (out_core0),
        .inst           (inst)
    );

endmodule
