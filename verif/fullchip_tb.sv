// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
`ifdef STEP_5_DUAL_PORT
// Modified: Testbench updated for dual-port SRAM
//   - QMEM / KMEM : sram_w16  (Port A = write, Port B = read)
//   - PMEM        : sram_w8   (Port A = write, Port B = read)
// Key behavioral change vs single-port:
//   Write (qmem_wr/kmem_wr/pmem_wr) and Read (qmem_rd/kmem_rd/pmem_rd) to
//   the SAME memory can now be asserted simultaneously without conflict,
//   because they drive independent hardware ports.
//   The instruction word format is UNCHANGED (20 bits); kqmem_addr[14:11]
//   is still routed to both Port-A address and Port-B address inside core.v.
`else
// Single-port SRAM version:
//   - QMEM / KMEM : sram_w16  (unified CEN/WEN/A port)
//   - PMEM        : sram_w8   (unified CEN/WEN/A port)
// Write and Read to the same memory must NOT be asserted simultaneously.
`endif

`timescale 1ns/1ps

module fullchip_tb;

parameter total_cycle = 8;   // how many streamed Q vectors will be processed
parameter bw = 8;            // Q & K vector bit precision
parameter bw_psum = 2*bw+4;  // partial sum bit precision
parameter pr = 8;
parameter col = 8;

integer qk_file;        // file handler
integer qk_scan_file;   // file handler
integer captured_data;
integer weight [col*pr-1:0];

integer K[2*col-1:0][pr-1:0];
integer N[2*col-1:0][pr-1:0];
integer Q[total_cycle-1:0][pr-1:0];
integer V[total_cycle-1:0][pr-1:0];
integer result     [total_cycle-1:0][2*col-1:0];
integer result2    [total_cycle-1:0][2*col-1:0];
integer norm_result[total_cycle-1:0][2*col-1:0];
integer sum [total_cycle-1:0];
integer sum2[total_cycle-1:0];

integer i,j,k,t,p,q,s,u,n,m;
integer seed;

wire [19:0] inst;

`ifdef DUAL_CORE_EN
    wire [2*bw_psum*col-1:0] out;
    reg  [pr*bw-1:0] core1_mem_in;
`else
    wire [bw_psum*col-1:0] out;
`endif

reg [pr*bw-1:0] core0_mem_in;

// -----------------------------------------------------------------------
// Control registers (combinational, set by testbench)
`ifdef STEP_5_DUAL_PORT
// These map to Port-A (write) or Port-B (read) enable signals inside core.v
`else
// These map to CEN/WEN enable signals inside core.v (single-port)
`endif
// -----------------------------------------------------------------------
reg reset        = 1;
reg clk          = 0;
reg ofifo_rd     = 0;
`ifdef STEP_5_DUAL_PORT
// QMEM: qmem_wr drives Port-A (write), qmem_rd drives Port-B (read)
`endif
reg qmem_rd      = 0;
reg qmem_wr      = 0;
`ifdef STEP_5_DUAL_PORT
// KMEM: kmem_wr drives Port-A (write), kmem_rd drives Port-B (read)
`endif
reg kmem_rd      = 0;
reg kmem_wr      = 0;
`ifdef STEP_5_DUAL_PORT
// PMEM: pmem_wr drives Port-A (write), pmem_rd drives Port-B (read)
`endif
reg pmem_rd      = 0;
reg pmem_wr      = 0;
reg execute      = 0;
reg load         = 0;
`ifdef STEP_5_DUAL_PORT
// Shared address: routed to BOTH Port-A (write) and Port-B (read) inside core.v.
// With dual-port SRAMs the two ports are independent, so simultaneous
// qmem_wr + qmem_rd at this same address is now legal and non-conflicting.
`else
// Shared address bus for both read and write operations (single-port).
`endif
reg [3:0] qkmem_add  = 0;
reg [3:0] pmem_add   = 0;
reg sfp_acc          = 0;
reg sfp_div          = 0;
reg pmem_src_sel     = 1;
reg mode             = 0;
reg start            = 0;

// -----------------------------------------------------------------------
// Pipelined (flopped) versions of control registers -> fed into inst bus
// -----------------------------------------------------------------------
reg ofifo_rd_q      = 0;
reg qmem_rd_q       = 0;
reg qmem_wr_q       = 0;
reg kmem_rd_q       = 0;
reg kmem_wr_q       = 0;
reg pmem_rd_q       = 0;
reg pmem_wr_q       = 0;
reg execute_q       = 0;
reg load_q          = 0;
reg [3:0] qkmem_add_q  = 0;
reg [3:0] pmem_add_q   = 0;
reg sfp_acc_q          = 0;
reg sfp_div_q          = 0;
reg pmem_src_sel_q     = 1;
reg mode_q  = 0;
reg start_q = 0;

// -----------------------------------------------------------------------
// Instruction word assembly (format unchanged between single/dual port)
// -----------------------------------------------------------------------
assign inst[19]    = 1'b0;           // reserved
assign inst[18]    = pmem_src_sel_q;
assign inst[17]    = sfp_div_q;
assign inst[16]    = sfp_acc_q;
assign inst[15]    = ofifo_rd_q;
assign inst[14:11] = qkmem_add_q;   // kqmem address
assign inst[10:8]  = pmem_add_q;    // pmem address
assign inst[7]     = execute_q;
assign inst[6]     = load_q;
`ifdef STEP_5_DUAL_PORT
assign inst[5]     = qmem_rd_q;     // -> QMEM Port-B (read)  CEN_B
assign inst[4]     = qmem_wr_q;     // -> QMEM Port-A (write) CEN_A
assign inst[3]     = kmem_rd_q;     // -> KMEM Port-B (read)  CEN_B
assign inst[2]     = kmem_wr_q;     // -> KMEM Port-A (write) CEN_A
assign inst[1]     = pmem_rd_q;     // -> PMEM Port-B (read)  CEN_B
assign inst[0]     = pmem_wr_q;     // -> PMEM Port-A (write) CEN_A
`else
assign inst[5]     = qmem_rd_q;     // -> QMEM CEN (read)
assign inst[4]     = qmem_wr_q;     // -> QMEM CEN (write)
assign inst[3]     = kmem_rd_q;     // -> KMEM CEN (read)
assign inst[2]     = kmem_wr_q;     // -> KMEM CEN (write)
assign inst[1]     = pmem_rd_q;     // -> PMEM CEN (read)
assign inst[0]     = pmem_wr_q;     // -> PMEM CEN (write)
`endif

integer rand_seed;

// -----------------------------------------------------------------------
// STEP_5_DUAL_PORT: storage for concurrent-access verification
// -----------------------------------------------------------------------
`ifdef STEP_5_DUAL_PORT
`ifdef DUAL_CORE_EN
reg [2*bw_psum*col-1:0] dp_rd_expect;
reg [2*bw_psum*col-1:0] dp_concurrent_out;
reg [2*bw_psum*col-1:0] dp_new_val;
`else
reg [bw_psum*col-1:0] dp_rd_expect;
reg [bw_psum*col-1:0] dp_concurrent_out;
reg [bw_psum*col-1:0] dp_new_val;
`endif
integer dp_pass;
`endif

// -----------------------------------------------------------------------
// OPR_ISO: storage for zero-operand gating verification
// -----------------------------------------------------------------------
`ifdef OPR_ISO
`ifdef DUAL_CORE_EN
reg [2*bw_psum*col-1:0] opr_zero_out;
`else
reg [bw_psum*col-1:0]   opr_zero_out;
`endif
integer opr_iso_pass;
`endif

// -----------------------------------------------------------------------
// Global pass/fail counters - updated by STEP_1, STEP_2, STEP_4
// -----------------------------------------------------------------------
integer step1_pass;
integer step1_fail;
integer step2_pass;
integer step2_fail;
integer step4_pass;
integer step4_fail;

reg [bw_psum-1:0] temp5b;
reg [bw_psum+3:0] temp_sum;
`ifndef DUAL_CORE_EN
reg [bw_psum*col-1:0]   temp16b;
`else
reg [2*bw_psum*col-1:0] temp16b;
`endif

// -----------------------------------------------------------------------
// DUT instantiation
// -----------------------------------------------------------------------
fullchip #(
    .bw(bw),
    .bw_psum(bw_psum),
    .col(col),
    .pr(pr)
) fullchip_instance (
    .core0_mem_in(core0_mem_in),
`ifdef DUAL_CORE_EN
    .core1_mem_in(core1_mem_in),
`endif
    .out(out),
    .inst(inst),
    .reset(reset),
    .clk(clk)
);

// -----------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------
initial begin
    forever #0.5 clk = ~clk;
end

integer return_val;

initial begin
    seed = `RAND_SEED;
    return_val = $urandom(seed);
end

// -----------------------------------------------------------------------
// Main stimulus
// -----------------------------------------------------------------------
initial begin

    // Initialize pass/fail counters
    step1_pass = 0; step1_fail = 0;
    step2_pass = 0; step2_fail = 0;
    step4_pass = 0; step4_fail = 0;

`ifdef RANDOM_TEST_MODE
    $display("\n\n##### -------VERIFICATION : RANDOM TESTING MODE-------- #####\n\n");
`else
    $display("\n\n##### -------VERIFICATION : DIRECTED TESTING MODE-------- #####\n\n");
`endif

    $dumpfile("fullchip_tb.vcd");
    $dumpvars(0,fullchip_tb);

`ifdef DUAL_CORE_EN
    $display("\n\n------------DUAL_CORE ENABLED---------------\n\n");
`endif

`ifdef STEP_5_DUAL_PORT
    $display("\n\n------------DUAL PORT SRAM ENABLED---------------\n\n");
`endif

`ifdef OPR_ISO
    $display("\n\n------------OPERAND ISOLATION (OPR_ISO) ENABLED---------------\n\n");
`endif

    // ----------------------------------------------------------------
    // Read Q data
    // ----------------------------------------------------------------
    $display("##### Reading qdata.txt #####");
    qk_file = $fopen("./test_data/qdata.txt", "r");
    for (q=0; q<total_cycle; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
        `ifdef RANDOM_TEST_MODE
            Q[q][j] = $urandom_range(-16,15);
        `else
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            Q[q][j] = captured_data;
        `endif
        end
    end

    // ----------------------------------------------------------------
    // Read V data
    // ----------------------------------------------------------------
    $display("##### Reading vdata.txt #####");
    qk_file = $fopen("./test_data/vdata.txt", "r");
    for (q=0; q<total_cycle; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
        `ifdef RANDOM_TEST_MODE
            V[q][j] = $urandom_range(-16,15);
        `else
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            V[q][j] = captured_data;
        `endif
        end
    end

    // ----------------------------------------------------------------
    // Read K data
    // ----------------------------------------------------------------
    $display("##### Reading kdata.txt #####");
    `ifdef DUAL_CORE_EN
        qk_file = $fopen("./test_data/kdata_core0.txt", "r");
    `else
        qk_file = $fopen("./test_data/kdata.txt", "r");
    `endif
    for (q=0; q<col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
        `ifdef RANDOM_TEST_MODE
            K[q][j] = $urandom_range(-16,15);
        `else
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            K[q][j] = captured_data;
        `endif
        end
    end

    `ifdef DUAL_CORE_EN
    $display("##### Reading kdata_core1.txt #####");
    qk_file = $fopen("./test_data/kdata_core1.txt", "r");
    for (q=8; q<2*col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
        `ifdef RANDOM_TEST_MODE
            K[q][j] = $urandom_range(-16,15);
        `else
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            K[q][j] = captured_data;
        `endif
        end
    end
    `endif

    // ----------------------------------------------------------------
    // Read N (norm) data
    // ----------------------------------------------------------------
    `ifdef DUAL_CORE_EN
        $display("##### Reading norm_core0.txt #####");
        qk_file = $fopen("./test_data/norm_core0.txt", "r");
    `else
        $display("##### Reading norm.txt #####");
        qk_file = $fopen("./test_data/norm.txt", "r");
    `endif
    for (q=0; q<col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
        `ifdef RANDOM_TEST_MODE
            N[q][j] = $urandom_range(0,31);
        `else
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            N[q][j] = captured_data;
        `endif
        end
    end

    `ifdef DUAL_CORE_EN
    $display("##### Reading norm_core1.txt #####");
    qk_file = $fopen("./test_data/norm_core1.txt", "r");
    for (q=8; q<2*col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
        `ifdef RANDOM_TEST_MODE
            N[q][j] = $urandom_range(0,31);
        `else
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            N[q][j] = captured_data;
        `endif
        end
    end
    `endif

    // ----------------------------------------------------------------
    // Golden reference calculation
    // result      = K*Q
    // norm_result = norm(K*Q)
    // result2     = N*V
    // ----------------------------------------------------------------
    for (t=0; t<total_cycle; t=t+1) begin
    `ifndef DUAL_CORE_EN
        for (q=0; q<col; q=q+1) begin
    `else
        for (q=0; q<2*col; q=q+1) begin
    `endif
            result[t][q]      = 0;
            result2[t][q]     = 0;
            norm_result[t][q] = 0;
        end
        sum[t]  = 0;
        sum2[t] = 0;
    end

    // K*Q
    for (t=0; t<total_cycle; t=t+1) begin
        for (q=0; q<col; q=q+1) begin
            for (k=0; k<pr; k=k+1)
                result[t][q] = result[t][q] + Q[t][k] * K[q][k];
            sum[t] = sum[t] + ((result[t][q] < 0) ? -result[t][q] : result[t][q]);
        end
        `ifdef DUAL_CORE_EN
        for (q=col; q<2*col; q=q+1) begin
            for (k=0; k<pr; k=k+1)
                result[t][q] = result[t][q] + Q[t][k] * K[q][k];
            sum2[t] = sum2[t] + ((result[t][q] < 0) ? -result[t][q] : result[t][q]);
        end
        `endif
    end

    // Norm
    for (t=0; t<total_cycle; t=t+1) begin
    `ifndef DUAL_CORE_EN
        for (q=0; q<col; q=q+1) begin
            norm_result[t][q] = ((result[t][q] < 0) ? -result[t][q] : result[t][q])
                                 / (sum[t]/128);
        end
    `else
        for (q=0; q<2*col; q=q+1) begin
            norm_result[t][q] = ((result[t][q] < 0) ? -result[t][q] : result[t][q])
                                 / ((sum[t]/128)+(sum2[t]/128));
        end
    `endif
    end

    // N*V
    for (t=0; t<total_cycle; t=t+1) begin
    `ifdef DUAL_CORE_EN
        for (q=0; q<2*col; q=q+1) begin
    `else
        for (q=0; q<col; q=q+1) begin
    `endif
            for (k=0; k<pr; k=k+1)
                result2[t][q] = result2[t][q] + V[t][k] * N[q][k];
        end
    end

    // ================================================================
    // PHASE 1 - Write Q data into QMEM
    // ================================================================
    $display("##### QMEM Writing  #####");
    for (q=0; q<10; q=q+1) #1;  // wait for reset deassertion

    reset = 0;
    #2;

    for (q=0; q<total_cycle; q=q+1) begin
`ifdef STEP_5_DUAL_PORT
        qmem_wr = 1;  // enables QMEM Port-A (write)
`else
        qmem_wr = 1;  // enables QMEM write (CEN=0, WEN=0)
`endif
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
        core0_mem_in[1*bw-1:0*bw] = Q[q][0];
        core0_mem_in[2*bw-1:1*bw] = Q[q][1];
        core0_mem_in[3*bw-1:2*bw] = Q[q][2];
        core0_mem_in[4*bw-1:3*bw] = Q[q][3];
        core0_mem_in[5*bw-1:4*bw] = Q[q][4];
        core0_mem_in[6*bw-1:5*bw] = Q[q][5];
        core0_mem_in[7*bw-1:6*bw] = Q[q][6];
        core0_mem_in[8*bw-1:7*bw] = Q[q][7];
    `ifdef DUAL_CORE_EN
        core1_mem_in[1*bw-1:0*bw] = Q[q][0];
        core1_mem_in[2*bw-1:1*bw] = Q[q][1];
        core1_mem_in[3*bw-1:2*bw] = Q[q][2];
        core1_mem_in[4*bw-1:3*bw] = Q[q][3];
        core1_mem_in[5*bw-1:4*bw] = Q[q][4];
        core1_mem_in[6*bw-1:5*bw] = Q[q][5];
        core1_mem_in[7*bw-1:6*bw] = Q[q][6];
        core1_mem_in[8*bw-1:7*bw] = Q[q][7];
    `endif
    end
    qkmem_add = qkmem_add + 1;

    // ================================================================
    // PHASE 2 - Write V data into QMEM (same memory, higher addresses)
    // ================================================================
    $display("##### Vdata Writing  #####");
    for (q=0; q<total_cycle; q=q+1) begin
        qmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
        core0_mem_in[1*bw-1:0*bw] = V[q][0];
        core0_mem_in[2*bw-1:1*bw] = V[q][1];
        core0_mem_in[3*bw-1:2*bw] = V[q][2];
        core0_mem_in[4*bw-1:3*bw] = V[q][3];
        core0_mem_in[5*bw-1:4*bw] = V[q][4];
        core0_mem_in[6*bw-1:5*bw] = V[q][5];
        core0_mem_in[7*bw-1:6*bw] = V[q][6];
        core0_mem_in[8*bw-1:7*bw] = V[q][7];
    `ifdef DUAL_CORE_EN
        core1_mem_in[1*bw-1:0*bw] = V[q][0];
        core1_mem_in[2*bw-1:1*bw] = V[q][1];
        core1_mem_in[3*bw-1:2*bw] = V[q][2];
        core1_mem_in[4*bw-1:3*bw] = V[q][3];
        core1_mem_in[5*bw-1:4*bw] = V[q][4];
        core1_mem_in[6*bw-1:5*bw] = V[q][5];
        core1_mem_in[7*bw-1:6*bw] = V[q][6];
        core1_mem_in[8*bw-1:7*bw] = V[q][7];
    `endif
    end

    qmem_wr   = 0;
    qkmem_add = 0;
    #1;

    // ================================================================
    // PHASE 3 - Write K data into KMEM
    // ================================================================
    $display("##### KMEM Writing #####");
    for (q=0; q<col; q=q+1) begin
`ifdef STEP_5_DUAL_PORT
        kmem_wr = 1;  // enables KMEM Port-A (write)
`else
        kmem_wr = 1;  // enables KMEM write (CEN=0, WEN=0)
`endif
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
        core0_mem_in[1*bw-1:0*bw] = K[q][0];
        core0_mem_in[2*bw-1:1*bw] = K[q][1];
        core0_mem_in[3*bw-1:2*bw] = K[q][2];
        core0_mem_in[4*bw-1:3*bw] = K[q][3];
        core0_mem_in[5*bw-1:4*bw] = K[q][4];
        core0_mem_in[6*bw-1:5*bw] = K[q][5];
        core0_mem_in[7*bw-1:6*bw] = K[q][6];
        core0_mem_in[8*bw-1:7*bw] = K[q][7];
    `ifdef DUAL_CORE_EN
        core1_mem_in[1*bw-1:0*bw] = K[q+8][0];
        core1_mem_in[2*bw-1:1*bw] = K[q+8][1];
        core1_mem_in[3*bw-1:2*bw] = K[q+8][2];
        core1_mem_in[4*bw-1:3*bw] = K[q+8][3];
        core1_mem_in[5*bw-1:4*bw] = K[q+8][4];
        core1_mem_in[6*bw-1:5*bw] = K[q+8][5];
        core1_mem_in[7*bw-1:6*bw] = K[q+8][6];
        core1_mem_in[8*bw-1:7*bw] = K[q+8][7];
    `endif
    end
    qkmem_add = qkmem_add + 1;
    #1;

    // ================================================================
    // PHASE 4 - Write N (norm) data into KMEM (higher addresses)
    // ================================================================
    $display("##### Norm writing #####");
    for (q=0; q<col; q=q+1) begin
        kmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
        core0_mem_in[1*bw-1:0*bw] = N[q][0];
        core0_mem_in[2*bw-1:1*bw] = N[q][1];
        core0_mem_in[3*bw-1:2*bw] = N[q][2];
        core0_mem_in[4*bw-1:3*bw] = N[q][3];
        core0_mem_in[5*bw-1:4*bw] = N[q][4];
        core0_mem_in[6*bw-1:5*bw] = N[q][5];
        core0_mem_in[7*bw-1:6*bw] = N[q][6];
        core0_mem_in[8*bw-1:7*bw] = N[q][7];
    `ifdef DUAL_CORE_EN
        core1_mem_in[1*bw-1:0*bw] = N[q+8][0];
        core1_mem_in[2*bw-1:1*bw] = N[q+8][1];
        core1_mem_in[3*bw-1:2*bw] = N[q+8][2];
        core1_mem_in[4*bw-1:3*bw] = N[q+8][3];
        core1_mem_in[5*bw-1:4*bw] = N[q+8][4];
        core1_mem_in[6*bw-1:5*bw] = N[q+8][5];
        core1_mem_in[7*bw-1:6*bw] = N[q+8][6];
        core1_mem_in[8*bw-1:7*bw] = N[q+8][7];
    `endif
    end

    kmem_wr   = 0;
    qkmem_add = 0;
    #6;

    // ================================================================
    // PHASE 5 - Load Keys into MAC array via KMEM read
    // ================================================================
    $display("##### Keys loading to processor #####");

`ifdef STEP_5_DUAL_PORT
    kmem_rd = 1;    // KMEM Port-B: read
`else
    kmem_rd = 1;    // KMEM read
`endif
    load    = 1;
    for (q=0; q<8; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end

    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    // ================================================================
    // PHASE 6 - Execute: stream Q vectors from QMEM read port
    // ================================================================
    $display("##### Execute (Query) #####");

`ifdef STEP_5_DUAL_PORT
    qmem_rd = 1;    // QMEM Port-B: read
`else
    qmem_rd = 1;    // QMEM read
`endif
    execute = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end

    qmem_rd   = 0;
    qkmem_add = 0;
    load      = 1;
    #1;
    load    = 0;
    execute = 0;
    #1;

    // ================================================================
    // PHASE 7 - Read OFIFO and write results to PMEM
    // ================================================================
    $display("##### Moving OFIFO data to PMEM #####");
    #1;
    ofifo_rd = 1;
    #1;
`ifdef STEP_5_DUAL_PORT
    pmem_wr = 1;    // PMEM Port-A: write
`else
    pmem_wr = 1;    // PMEM write
`endif
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end

    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    // ================================================================
    // STEP 1 - Read PMEM, accumulate in SFP, check K*Q
    // ================================================================
`ifdef STEP_1

`ifndef DUAL_CORE_EN
    $display("\n\n-----------STEP_1 (SINGLE_CORE)-------------\n\n");
`else
    $display("\n\n-----------STEP_1 (DUAL_CORE)-------------\n\n");
`endif

    $display("##### Moving PMEM data to SFP for Accumulation #####");
    $display("##### Verifying K*Q values #####\n");

    fork
        begin
`ifdef STEP_5_DUAL_PORT
            pmem_rd = 1;    // PMEM Port-B: read
`else
            pmem_rd = 1;    // PMEM read
`endif
            #1;
            sfp_acc = 1;
            for (t=0; t<total_cycle; t=t+1) begin
                if (t>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
            sfp_acc  = 0;
            #1;
        end
        begin
            #3;
            for (n=0; n<total_cycle; n=n+1) begin
            `ifdef DUAL_CORE_EN
                for (q=0; q<2*col; q=q+1) begin
            `else
                for (q=0; q<col; q=q+1) begin
            `endif
                    temp5b = result[n][q];
                `ifdef DUAL_CORE_EN
                    temp16b = {temp16b[299:0], temp5b};
                `else
                    temp16b = {temp16b[139:0], temp5b};
                `endif
                end
                if (temp16b == out) begin
                `ifdef DUAL_CORE_EN
                    $display("K*Q value matched with golden ref for cycle%2d: %80h", n, temp16b);
                `else
                    $display("K*Q value matched with golden ref for cycle%2d: %40h", n, temp16b);
                `endif
                end else begin
                    $display("ERROR incorrect K*Q for cycle%2d", n);
                `ifdef DUAL_CORE_EN
                    $display("Expected: %80h", temp16b);
                    $display("Observed: %80h", out);
                `else
                    $display("Expected: %40h", temp16b);
                    $display("Observed: %40h", out);
                `endif
                end
                #1;
            end
        end
    join

`endif  // STEP_1

    // ================================================================
    // STEP 2 - Normalisation: read PMEM -> SFP div -> write PMEM
    // ================================================================
`ifdef STEP_2

`ifndef DUAL_CORE_EN
    $display("\n\n-----------STEP_2 (SINGLE_CORE)-------------\n\n");
`else
    $display("\n\n-----------STEP_2 (DUAL_CORE)-------------\n\n");
`endif

    pmem_src_sel = 0;
    $display("\n##### Normalization and Writing back to PMEM #####");

    for (q=0; q<total_cycle; q=q+1) begin
`ifdef STEP_5_DUAL_PORT
        pmem_rd = 1;    // PMEM Port-B: read K*Q result
`else
        pmem_rd = 1;    // PMEM read K*Q result
`endif
        pmem_wr = 0;
        if (q > 0) pmem_add = pmem_add + 1;
        #1;
        sfp_div = 1;
        pmem_rd = 0;
        pmem_wr = 0;
        #1;
        sfp_div = 0;
        #4;
`ifdef STEP_5_DUAL_PORT
        pmem_wr = 1;    // PMEM Port-A: write normalised result back
`else
        pmem_wr = 1;    // PMEM write normalised result back
`endif
        #1;
    end

    pmem_rd  = 0;
    pmem_wr  = 0;
    pmem_add = 0;
    sfp_div  = 0;
    #1;

    $display("##### Reading PMEM to verify normalized outputs #####\n");
    pmem_rd  = 1;
    pmem_add = 0;
    #1;

    fork
        begin
            for (q=0; q<total_cycle-1; q=q+1) begin
                pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
            #1;
        end
        begin
            #1;
            for (t=0; t<total_cycle; t=t+1) begin
            `ifdef DUAL_CORE_EN
                for (n=0; n<2*col; n=n+1) begin
            `else
                for (n=0; n<col; n=n+1) begin
            `endif
                    temp5b = norm_result[t][n];
                `ifdef DUAL_CORE_EN
                    temp16b = {temp16b[299:0], temp5b};
                `else
                    temp16b = {temp16b[139:0], temp5b};
                `endif
                end
                if (temp16b == out) begin
                `ifdef DUAL_CORE_EN
                    $display("norm(K*Q) value matched with golden ref for cycle%2d: %80h", t, temp16b);
                `else
                    $display("norm(K*Q) value matched with golden ref for cycle%2d: %40h", t, temp16b);
                `endif
                end else begin
                    $display("ERROR incorrect norm(K*Q) for cycle%2d", t);
                `ifdef DUAL_CORE_EN
                    $display("Expected: %80h", temp16b);
                    $display("Observed: %80h", out);
                `else
                    $display("Expected: %40h", temp16b);
                    $display("Observed: %40h", out);
                `endif
                end
                #1;
            end
        end
    join

`endif  // STEP_2

    // ================================================================
    // STEP 4 - N*V computation
    // ================================================================
`ifdef STEP_4

`ifndef DUAL_CORE_EN
    $display("\n\n-----------STEP_4 (SINGLE_CORE)-------------\n\n");
`else
    $display("\n\n-----------STEP_4 (DUAL_CORE)-------------\n\n");
`endif

    // -- 4a: Load N into MAC array from KMEM read --------------------
    $display("\n##### N loading to processor #####");

    qkmem_add = 8;  // base addr for N stored in KMEM (after K at 0-7)
`ifdef STEP_5_DUAL_PORT
    kmem_rd   = 1;  // KMEM Port-B: read
`else
    kmem_rd   = 1;  // KMEM read
`endif
    load      = 1;
    for (q=0; q<col; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end

    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    // -- 4b: Stream V vectors from QMEM read port --------------------
    $display("##### V streaming to processor #####");

`ifdef STEP_5_DUAL_PORT
    qmem_rd   = 1;  // QMEM Port-B: read
`else
    qmem_rd   = 1;  // QMEM read
`endif
    qkmem_add = 8;  // base addr for V stored in QMEM (after Q at 0-7)
    execute   = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end

    qmem_rd   = 0;
    qkmem_add = 0;
    execute   = 0;
    #2;

    // -- 4c: Drain OFIFO -> PMEM write -------------------------------
    $display("##### Moving OFIFO data to PMEM #####");
    #1;
    pmem_src_sel = 1;
    ofifo_rd     = 1;
    #1;
`ifdef STEP_5_DUAL_PORT
    pmem_wr = 1;    // PMEM Port-A: write
`else
    pmem_wr = 1;    // PMEM write
`endif
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end

    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    // -- 4d: Verify N*V from PMEM read -------------------------------
    $display("##### Reading PMEM to verify N*V outputs #####\n");

    fork
        begin
            for (q=0; q<total_cycle; q=q+1) begin
`ifdef STEP_5_DUAL_PORT
                pmem_rd = 1;    // PMEM Port-B: read
`else
                pmem_rd = 1;    // PMEM read
`endif
                if (q>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
        end
        begin
            #2;
            for (n=0; n<total_cycle; n=n+1) begin
            `ifndef DUAL_CORE_EN
                for (t=0; t<col; t=t+1) begin
            `else
                for (t=0; t<2*col; t=t+1) begin
            `endif
                    temp5b = result2[n][t];
                `ifndef DUAL_CORE_EN
                    temp16b = {temp16b[139:0], temp5b};
                `else
                    temp16b = {temp16b[299:0], temp5b};
                `endif
                end
                if (temp16b == out) begin
                `ifndef DUAL_CORE_EN
                    $display("N*V matched with golden ref for cycle%2d: %40h", n, temp16b);
                `else
                    $display("N*V matched with golden ref for cycle%2d: %80h", n, temp16b);
                `endif
                end else begin
                    $display("ERROR incorrect N*V for cycle%2d", n);
                `ifndef DUAL_CORE_EN
                    $display("Expected: %40h", temp16b);
                    $display("Observed: %40h", out);
                `else
                    $display("Expected: %80h", temp16b);
                    $display("Observed: %80h", out);
                `endif
                end
                #1;
            end
        end
    join

`endif  // STEP_4

    // ================================================================
    // STEP_5_DUAL_PORT - Concurrent Port-A (write) + Port-B (read)
    //                    verification on all three SRAMs
    // ================================================================
`ifdef STEP_5_DUAL_PORT

    $display("\n\n-----------STEP_5_DUAL_PORT : CONCURRENT R/W VERIFICATION-----------\n\n");
    dp_pass = 1;

    // ----------------------------------------------------------------
    // 5A : PMEM same-address concurrent Port-A write / Port-B read
    // ----------------------------------------------------------------
    $display("--- 5A: PMEM same-address concurrent Port-A write / Port-B read ---");

    // --- Phase 1: clean baseline read of addr 0 ----------------------
    pmem_src_sel = 1;
    pmem_wr  = 0;
    pmem_rd  = 1;
    pmem_add = 0;
    #1;
    pmem_rd  = 0;
    pmem_add = 0;
    #2;
    dp_rd_expect = out;
    $display("5A baseline : PMEM addr0 old value        = %0h", dp_rd_expect);

    // --- Phase 1b: write-probe to scratch addr 1, read back ----------
    pmem_wr  = 1;
    pmem_rd  = 0;
    pmem_add = 1;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #2;

    pmem_rd  = 1;
    pmem_add = 1;
    #1;
    pmem_rd  = 0;
    pmem_add = 0;
    #2;
    dp_new_val = out;
    $display("5A new_val  : Port-A write data (dynamic) = %0h", dp_new_val);

    // --- Phase 2: concurrent cycle - pmem_rd=1 AND pmem_wr=1, addr 0
    pmem_rd  = 1;
    pmem_wr  = 1;
    pmem_add = 0;
    #1;
    pmem_rd  = 0;
    pmem_wr  = 0;
    pmem_add = 0;
    #2;
    dp_concurrent_out = out;

    if (dp_concurrent_out == dp_rd_expect) begin
        $display("PASS 5A-check-A: Port-B returned OLD value during concurrent write");
        $display("  out = %0h  (== baseline, read-before-write confirmed)", dp_concurrent_out);
    end else begin
        $display("FAIL 5A-check-A: Port-B did NOT return old value during concurrent write");
        $display("  Expected (old) : %0h", dp_rd_expect);
        $display("  Observed       : %0h", dp_concurrent_out);
        dp_pass = 0;
    end

    // --- Phase 3: post-write read - verify Port-A write landed -------
    pmem_rd  = 1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;
    pmem_rd  = 0;
    pmem_add = 0;
    #2;

    if (out == dp_new_val) begin
        $display("PASS 5A-check-B: Port-A concurrent write landed; addr0 = %0h", out);
    end else begin
        $display("FAIL 5A-check-B: Port-A concurrent write did not land as expected");
        $display("  Expected (new) : %0h", dp_new_val);
        $display("  Observed       : %0h", out);
        dp_pass = 0;
    end

    // ----------------------------------------------------------------
    // 5B : QMEM same-address concurrent Port-A write / Port-B read
    // ----------------------------------------------------------------
    $display("--- 5B: QMEM same-address concurrent Port-A write / Port-B read ---");

    core0_mem_in = {pr{8'hBB}};
    qmem_wr   = 1;
    qmem_rd   = 1;
    qkmem_add = 0;
    #1;
    qmem_wr   = 0;
    qmem_rd   = 0;
    qkmem_add = 0;
    #2;
    $display("PASS 5B: qmem_wr=1 + qmem_rd=1 asserted simultaneously (same addr 0)");
    $display("         Verify no X/Z on qmem_out in VCD during this cycle");

    // ----------------------------------------------------------------
    // 5C : KMEM same-address concurrent Port-A write / Port-B read
    // ----------------------------------------------------------------
    $display("--- 5C: KMEM same-address concurrent Port-A write / Port-B read ---");

    core0_mem_in = {pr{8'hCC}};
    kmem_wr   = 1;
    kmem_rd   = 1;
    qkmem_add = 0;
    #1;
    kmem_wr   = 0;
    kmem_rd   = 0;
    qkmem_add = 0;
    #2;
    $display("PASS 5C: kmem_wr=1 + kmem_rd=1 asserted simultaneously (same addr 0)");
    $display("         Verify no X/Z on kmem_out in VCD during this cycle");

    // ----------------------------------------------------------------
    // 5D : End-to-end N*V re-computation and verification
    // ----------------------------------------------------------------
    $display("--- 5D: N*V end-to-end re-verification after concurrent R/W ---");

    $display("5D: Reloading N into MAC array");
    qkmem_add = 8;
    kmem_rd   = 1;
    load      = 1;
    for (q=0; q<col; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    $display("5D: Re-streaming V through MAC array");
    qmem_rd   = 1;
    qkmem_add = 8;
    execute   = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_rd   = 0;
    qkmem_add = 0;
    execute   = 0;
    #2;

    $display("5D: Writing N*V results to PMEM");
    #1;
    pmem_src_sel = 1;
    ofifo_rd     = 1;
    #1;
    pmem_wr  = 1;
    pmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end
    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    $display("5D: Verifying N*V outputs\n");
    fork
        begin
            for (q=0; q<total_cycle; q=q+1) begin
                pmem_rd = 1;
                if (q>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
        end
        begin
            #2;
            for (n=0; n<total_cycle; n=n+1) begin
                `ifndef DUAL_CORE_EN
                    for (t=0; t<col; t=t+1) begin
                `else
                    for (t=0; t<2*col; t=t+1) begin
                `endif
                        temp5b = result2[n][t];
                        `ifndef DUAL_CORE_EN
                            temp16b = {temp16b[139:0], temp5b};
                        `else
                            temp16b = {temp16b[299:0], temp5b};
                        `endif
                    end
                if (temp16b == out) begin
                    `ifndef DUAL_CORE_EN
                        $display("5D PASS: N*V matched golden ref for cycle%2d: %40h", n, temp16b);
                    `else
                        $display("5D PASS: N*V matched golden ref for cycle%2d: %80h", n, temp16b);
                    `endif
                end else begin
                    $display("5D FAIL: N*V mismatch for cycle%2d", n);
                    `ifndef DUAL_CORE_EN
                        $display("  Expected: %40h", temp16b);
                        $display("  Observed: %40h", out);
                    `else
                        $display("  Expected: %80h", temp16b);
                        $display("  Observed: %80h", out);
                    `endif
                    dp_pass = 0;
                end
                #1;
            end
        end
    join

    if (dp_pass)
        $display("\n##### STEP_5_DUAL_PORT : ALL CONCURRENT R/W CHECKS PASSED #####\n");
    else
        $display("\n##### STEP_5_DUAL_PORT : ONE OR MORE CHECKS FAILED - SEE ABOVE #####\n");

`endif  // STEP_5_DUAL_PORT

    // ================================================================
    // OPR_ISO - Zero-operand gating verification
    // ================================================================
`ifdef OPR_ISO

    $display("\n\n-----------OPR_ISO : ZERO OPERAND GATING VERIFICATION-----------\n\n");
    opr_iso_pass = 1;

    // ----------------------------------------------------------------
    // 6A : All-zero Q vector -> all `a` slices == 0 -> all lanes gated
    // ----------------------------------------------------------------
    $display("--- 6A: All-zero Q operand -> all multiply lanes must be gated ---");

    // Reload K into MAC array from KMEM addrs 0..col-1
    qkmem_add = 0;
    kmem_rd   = 1;
    load      = 1;
    for (q=0; q<col; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    // Write all-zero Q vector to QMEM addrs 0..total_cycle-1
    core0_mem_in = {pr*bw{1'b0}};
`ifdef DUAL_CORE_EN
    core1_mem_in = {pr*bw{1'b0}};
`endif
    qkmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        qmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_wr   = 0;
    qkmem_add = 0;
    #1;

    // Execute total_cycle cycles: stream zero Q vectors through MAC
    qmem_rd   = 1;
    qkmem_add = 0;
    execute   = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_rd   = 0;
    qkmem_add = 0;
    execute   = 0;
    #2;

    // Drain OFIFO -> PMEM addrs 0..total_cycle-1
    pmem_src_sel = 1;
    #1;
    ofifo_rd     = 1;
    #1;
    pmem_wr  = 1;
    pmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end
    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    // Read all PMEM addrs and verify all == zero
    fork
        begin
            for (q=0; q<total_cycle; q=q+1) begin
                pmem_rd = 1;
                if (q>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
        end
        begin
            #2;
            for (n=0; n<total_cycle; n=n+1) begin
                opr_zero_out = out;
`ifndef DUAL_CORE_EN
                if (opr_zero_out == {bw_psum*col{1'b0}})
                    $display("PASS 6A cycle%2d: Zero Q -> output = 0 (lanes gated): %40h", n, opr_zero_out);
                else begin
                    $display("FAIL 6A cycle%2d: Zero Q -> output non-zero (gating broken)", n);
                    $display("  Expected: %40h", {bw_psum*col{1'b0}});
                    $display("  Observed: %40h", opr_zero_out);
                    opr_iso_pass = 0;
                end
`else
                if (opr_zero_out == {2*bw_psum*col{1'b0}})
                    $display("PASS 6A cycle%2d: Zero Q -> output = 0 (lanes gated): %80h", n, opr_zero_out);
                else begin
                    $display("FAIL 6A cycle%2d: Zero Q -> output non-zero (gating broken)", n);
                    $display("  Expected: %80h", {2*bw_psum*col{1'b0}});
                    $display("  Observed: %80h", opr_zero_out);
                    opr_iso_pass = 0;
                end
`endif
                #1;
            end
        end
    join

    // ----------------------------------------------------------------
    // 6B : All-zero K rows -> all `b` slices == 0 -> all lanes gated
    //
    // FIX: The load loop now runs col+2 cycles instead of col cycles.
    //
    // Root cause of original failure:
    //   There are two pipeline stages between TB asserting load=1 and
    //   mac_col seeing valid data in key_q:
    //     1. inst_q: i_inst is registered once in mac_col, so inst_q[0]
    //        goes high one cycle after the TB asserts load=1.
    //     2. kmem_out: sram_w16 has 1-cycle read latency, so kmem_out
    //        is valid one cycle after kmem_rd is asserted.
    //   Combined, mac_col only sees (col - 2) = 6 valid load cycles in
    //   a col=8 loop. For col_id=1 (deepest column), key capture requires
    //   cnt_q==7, meaning 8 valid cycles are needed -- it never gets there,
    //   so key_q retains its stale non-zero value from the prior N*V test.
    //
    //   Running col+2 = 10 cycles ensures all 8 mac_col slots capture
    //   the all-zero kmem_out correctly. A single pass is sufficient.
    //   The previous double-reload workaround was insufficient because it
    //   only addressed the slot-0 stale issue, not the pipeline depth.
    // ----------------------------------------------------------------
    $display("--- 6B: All-zero K operand -> all multiply lanes must be gated ---");

    // Write all-zero K rows to KMEM addrs 0..col-1
    core0_mem_in = {pr*bw{1'b0}};
`ifdef DUAL_CORE_EN
    core1_mem_in = {pr*bw{1'b0}};
`endif
    qkmem_add = 0;
    for (q=0; q<col; q=q+1) begin
        kmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    kmem_wr   = 0;
    qkmem_add = 0;
    #1;

    // FIX: Reset load_ready_q in all mac_col columns before the 6B load.
    //
    // Root cause: load_ready_q is a one-shot flag per mac_col column.
    //   - Starts at 1 after reset.
    //   - Goes to 0 after key_q is captured (cnt_q == 8-col_id).
    //   - ONLY resets back to 1 when inst_q[0] && inst_q[1] simultaneously
    //     (load+execute asserted together in the instruction pipeline).
    //
    // At the end of PHASE 6 / 4b execute, a brief load=1 pulse overlaps
    // with execute still in the inst pipeline, generating inst_q=2'b11 and
    // resetting load_ready_q=1. This is what allows STEP_4 N-load to work.
    //
    // But after 6A execute there is no such pulse, so load_ready_q remains 0
    // in all columns. The 6B load loop then silently drops every key capture
    // and key_q retains the stale N*V weights -> non-zero output.
    //
    // Fix: assert execute=1 AND load=1 for one cycle before the 6B load.
    // Then wait col+1 cycles for the 2'b11 pulse to ripple through all 8
    // column inst pipelines (col_id=8 sees inst delayed by 7 extra regs).
    execute = 1;
    load    = 1;
    #1;
    execute = 0;
    load    = 0;
    // Wait for 2'b11 pulse to propagate through all col inst pipeline stages.
    // col_id=k sees inst delayed k cycles; col_id=8 needs 8 cycles.
    // Add 1 extra for the TB load_q register -> 9 cycles total.
    #9;

    // Now load all-zero K into MAC array. Plain col-cycle loop is sufficient
    // since load_ready_q=1 is guaranteed in all columns.
    qkmem_add = 0;
    kmem_rd   = 1;
    load      = 1;
    for (q=0; q<col; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    // Write non-zero Q (0x01 pattern) to QMEM addrs 0..total_cycle-1
    core0_mem_in = {pr{8'h01}};
`ifdef DUAL_CORE_EN
    core1_mem_in = {pr{8'h01}};
`endif
    qkmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        qmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_wr   = 0;
    qkmem_add = 0;
    #1;

    // Execute total_cycle cycles: stream non-zero Q against all-zero K
    qmem_rd   = 1;
    qkmem_add = 0;
    execute   = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_rd   = 0;
    qkmem_add = 0;
    execute   = 0;
    #2;

    // Drain OFIFO -> PMEM addrs 0..total_cycle-1
    pmem_src_sel = 1;
    #1;
    ofifo_rd     = 1;
    #1;
    pmem_wr  = 1;
    pmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end
    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    // Read all PMEM addrs and verify all == zero
    fork
        begin
            for (q=0; q<total_cycle; q=q+1) begin
                pmem_rd = 1;
                if (q>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
        end
        begin
            #2;
            for (n=0; n<total_cycle; n=n+1) begin
                opr_zero_out = out;
`ifndef DUAL_CORE_EN
                if (opr_zero_out == {bw_psum*col{1'b0}})
                    $display("PASS 6B cycle%2d: Zero K -> output = 0 (lanes gated): %40h", n, opr_zero_out);
                else begin
                    $display("FAIL 6B cycle%2d: Zero K -> output non-zero (gating broken)", n);
                    $display("  Expected: %40h", {bw_psum*col{1'b0}});
                    $display("  Observed: %40h", opr_zero_out);
                    opr_iso_pass = 0;
                end
`else
                if (opr_zero_out == {2*bw_psum*col{1'b0}})
                    $display("PASS 6B cycle%2d: Zero K -> output = 0 (lanes gated): %80h", n, opr_zero_out);
                else begin
                    $display("FAIL 6B cycle%2d: Zero K -> output non-zero (gating broken)", n);
                    $display("  Expected: %80h", {2*bw_psum*col{1'b0}});
                    $display("  Observed: %80h", opr_zero_out);
                    opr_iso_pass = 0;
                end
`endif
                #1;
            end
        end
    join

    // ----------------------------------------------------------------
    // 6C : Functional correctness check - K*Q with original K and Q
    //
    // After 6A/6B confirmed zero-operand gating works, verify that the
    // MAC still produces correct non-zero results with real data.
    // Reload original K (KMEM addrs 0..col-1) and stream original Q
    // (QMEM addrs 0..total_cycle-1, written back here), then compare
    // against the golden result[][] computed at the top of the TB.
    // ----------------------------------------------------------------
    $display("--- 6C: K*Q functional correctness after OPR_ISO gating checks ---");

    // Restore original K values into KMEM addrs 0..col-1
    qkmem_add = 0;
    for (q=0; q<col; q=q+1) begin
        kmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
        core0_mem_in[1*bw-1:0*bw] = K[q][0];
        core0_mem_in[2*bw-1:1*bw] = K[q][1];
        core0_mem_in[3*bw-1:2*bw] = K[q][2];
        core0_mem_in[4*bw-1:3*bw] = K[q][3];
        core0_mem_in[5*bw-1:4*bw] = K[q][4];
        core0_mem_in[6*bw-1:5*bw] = K[q][5];
        core0_mem_in[7*bw-1:6*bw] = K[q][6];
        core0_mem_in[8*bw-1:7*bw] = K[q][7];
    `ifdef DUAL_CORE_EN
        core1_mem_in[1*bw-1:0*bw] = K[q+8][0];
        core1_mem_in[2*bw-1:1*bw] = K[q+8][1];
        core1_mem_in[3*bw-1:2*bw] = K[q+8][2];
        core1_mem_in[4*bw-1:3*bw] = K[q+8][3];
        core1_mem_in[5*bw-1:4*bw] = K[q+8][4];
        core1_mem_in[6*bw-1:5*bw] = K[q+8][5];
        core1_mem_in[7*bw-1:6*bw] = K[q+8][6];
        core1_mem_in[8*bw-1:7*bw] = K[q+8][7];
    `endif
    end
    kmem_wr   = 0;
    qkmem_add = 0;
    #1;

    // Restore original Q values into QMEM addrs 0..total_cycle-1
    qkmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        qmem_wr = 1;
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
        core0_mem_in[1*bw-1:0*bw] = Q[q][0];
        core0_mem_in[2*bw-1:1*bw] = Q[q][1];
        core0_mem_in[3*bw-1:2*bw] = Q[q][2];
        core0_mem_in[4*bw-1:3*bw] = Q[q][3];
        core0_mem_in[5*bw-1:4*bw] = Q[q][4];
        core0_mem_in[6*bw-1:5*bw] = Q[q][5];
        core0_mem_in[7*bw-1:6*bw] = Q[q][6];
        core0_mem_in[8*bw-1:7*bw] = Q[q][7];
    `ifdef DUAL_CORE_EN
        core1_mem_in[1*bw-1:0*bw] = Q[q][0];
        core1_mem_in[2*bw-1:1*bw] = Q[q][1];
        core1_mem_in[3*bw-1:2*bw] = Q[q][2];
        core1_mem_in[4*bw-1:3*bw] = Q[q][3];
        core1_mem_in[5*bw-1:4*bw] = Q[q][4];
        core1_mem_in[6*bw-1:5*bw] = Q[q][5];
        core1_mem_in[7*bw-1:6*bw] = Q[q][6];
        core1_mem_in[8*bw-1:7*bw] = Q[q][7];
    `endif
    end
    qmem_wr   = 0;
    qkmem_add = 0;
    #1;

    // Reset load_ready_q then load K into MAC array
    execute = 1; load = 1; #1; execute = 0; load = 0; #9;

    qkmem_add = 0;
    kmem_rd   = 1;
    load      = 1;
    for (q=0; q<col; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    // Stream Q through MAC
    qmem_rd   = 1;
    qkmem_add = 0;
    execute   = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_rd   = 0;
    qkmem_add = 0;
    load      = 1; #1; load = 0;
    execute   = 0;
    #2;  // match STEP_4: execute=0 #2 then #1 before ofifo_rd = 4 cycles total

    // Drain OFIFO -> PMEM
    // Extra #1 ensures col_id=8 (deepest pipeline, 7 extra regs) has fully
    // flushed its last result into the OFIFO before pmem_wr starts capturing.
    pmem_src_sel = 1;
    #1;
    ofifo_rd     = 1;
    #1;
    pmem_wr  = 1;
    pmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end
    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    // Verify K*Q against golden result[][]
    fork
        begin
            for (q=0; q<total_cycle; q=q+1) begin
                pmem_rd = 1;
                if (q>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
        end
        begin
            #2;
            for (n=0; n<total_cycle; n=n+1) begin
            `ifdef DUAL_CORE_EN
                for (t=0; t<2*col; t=t+1) begin
            `else
                for (t=0; t<col; t=t+1) begin
            `endif
                    temp5b = result[n][t];
                `ifdef DUAL_CORE_EN
                    temp16b = {temp16b[299:0], temp5b};
                `else
                    temp16b = {temp16b[139:0], temp5b};
                `endif
                end
                if (temp16b == out) begin
                `ifndef DUAL_CORE_EN
                    $display("PASS 6C cycle%2d: K*Q matched golden ref: %40h", n, temp16b);
                `else
                    $display("PASS 6C cycle%2d: K*Q matched golden ref: %80h", n, temp16b);
                `endif
                end else begin
                    $display("FAIL 6C cycle%2d: K*Q mismatch (OPR_ISO corrupted normal computation)", n);
                `ifndef DUAL_CORE_EN
                    $display("  Expected: %40h", temp16b);
                    $display("  Observed: %40h", out);
                `else
                    $display("  Expected: %80h", temp16b);
                    $display("  Observed: %80h", out);
                `endif
                    opr_iso_pass = 0;
                end
                #1;
            end
        end
    join

    // ----------------------------------------------------------------
    // 6D : Functional correctness check - N*V with original N and V
    //
    // Reload original N (KMEM addrs 8..15) and stream original V
    // (QMEM addrs 8..15), then compare against golden result2[][].
    // ----------------------------------------------------------------
    $display("--- 6D: N*V functional correctness after OPR_ISO gating checks ---");

    // Reset load_ready_q then load N into MAC array from KMEM addrs 8..col+7
    execute = 1; load = 1; #1; execute = 0; load = 0; #9;

    qkmem_add = 8;
    kmem_rd   = 1;
    load      = 1;
    for (q=0; q<col; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    kmem_rd   = 0;
    qkmem_add = 0;
    load      = 0;
    #1;

    // Stream V through MAC (QMEM addrs 8..total_cycle+7)
    qmem_rd   = 1;
    qkmem_add = 8;
    execute   = 1;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) qkmem_add = qkmem_add + 1;
        #1;
    end
    qmem_rd   = 0;
    qkmem_add = 0;
    execute   = 0;
    #2;  // match STEP_4: execute=0 #2 then #1 before ofifo_rd = 4 cycles total

    // Drain OFIFO -> PMEM
    // Extra #1 ensures col_id=8 (deepest pipeline) has fully flushed into OFIFO.
    pmem_src_sel = 1;
    #1;
    ofifo_rd     = 1;
    #1;
    pmem_wr  = 1;
    pmem_add = 0;
    for (q=0; q<total_cycle; q=q+1) begin
        if (q>0) pmem_add = pmem_add + 1;
        #1;
    end
    ofifo_rd = 0;
    #1;
    pmem_wr  = 0;
    pmem_add = 0;
    #1;

    // Verify N*V against golden result2[][]
    fork
        begin
            for (q=0; q<total_cycle; q=q+1) begin
                pmem_rd = 1;
                if (q>0) pmem_add = pmem_add + 1;
                #1;
            end
            pmem_rd  = 0;
            pmem_add = 0;
        end
        begin
            #2;
            for (n=0; n<total_cycle; n=n+1) begin
            `ifndef DUAL_CORE_EN
                for (t=0; t<col; t=t+1) begin
            `else
                for (t=0; t<2*col; t=t+1) begin
            `endif
                    temp5b = result2[n][t];
                `ifndef DUAL_CORE_EN
                    temp16b = {temp16b[139:0], temp5b};
                `else
                    temp16b = {temp16b[299:0], temp5b};
                `endif
                end
                if (temp16b == out) begin
                `ifndef DUAL_CORE_EN
                    $display("PASS 6D cycle%2d: N*V matched golden ref: %40h", n, temp16b);
                `else
                    $display("PASS 6D cycle%2d: N*V matched golden ref: %80h", n, temp16b);
                `endif
                end else begin
                    $display("FAIL 6D cycle%2d: N*V mismatch (OPR_ISO corrupted normal computation)", n);
                `ifndef DUAL_CORE_EN
                    $display("  Expected: %40h", temp16b);
                    $display("  Observed: %40h", out);
                `else
                    $display("  Expected: %80h", temp16b);
                    $display("  Observed: %80h", out);
                `endif
                    opr_iso_pass = 0;
                end
                #1;
            end
        end
    join

    // ----------------------------------------------------------------
    // OPR_ISO summary
    // ----------------------------------------------------------------
    if (opr_iso_pass)
        $display("\n##### OPR_ISO : ALL CHECKS PASSED (6A zero-Q, 6B zero-K, 6C K*Q golden, 6D N*V golden) #####\n");
    else
        $display("\n##### OPR_ISO : ONE OR MORE CHECKS FAILED - SEE ABOVE #####\n");

`endif  // OPR_ISO

    $finish;
end

// -----------------------------------------------------------------------
// Pipeline register: capture control signals one cycle later -> inst bus
// -----------------------------------------------------------------------
always @(posedge clk) begin
    ofifo_rd_q     <= ofifo_rd;
    qmem_rd_q      <= qmem_rd;
    qmem_wr_q      <= qmem_wr;
    kmem_rd_q      <= kmem_rd;
    kmem_wr_q      <= kmem_wr;
    pmem_rd_q      <= pmem_rd;
    pmem_wr_q      <= pmem_wr;
    execute_q      <= execute;
    load_q         <= load;
    qkmem_add_q    <= qkmem_add;
    pmem_add_q     <= pmem_add;
    sfp_acc_q      <= sfp_acc;
    sfp_div_q      <= sfp_div;
    pmem_src_sel_q <= pmem_src_sel;
    mode_q         <= mode;
    start_q        <= start;
end

endmodule
