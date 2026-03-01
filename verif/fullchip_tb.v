// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

`timescale 1ns/1ps

`define SEED 43

module fullchip_tb;

parameter total_cycle = 8;   // how many streamed Q vectors will be processed
parameter bw = 8;            // Q & K vector bit precision
parameter bw_psum = 2*bw+4;  // partial sum bit precision
parameter pr = 8;           
parameter col = 8;           

integer qk_file ; // file handler
integer qk_scan_file ; // file handler
integer captured_data;
integer weight [col*pr-1:0];
`define NULL 0

integer K[2*col-1:0][pr-1:0];
integer N[2*col-1:0][pr-1:0];
integer Q[total_cycle-1:0][pr-1:0];
integer V[total_cycle-1:0][pr-1:0];
integer result[total_cycle-1:0][2*col-1:0];
integer result2[total_cycle-1:0][2*col-1:0];
integer norm_result[total_cycle-1:0][2*col-1:0];
integer sum[total_cycle-1:0];
integer sum2[total_cycle-1:0];

integer i,j,k,t,p,q,s,u,n,m;
integer seed;

wire [19:0] inst;
wire [bw_psum*col-1:0] out;
reg [pr*bw-1:0] core0_mem_in; 

reg reset = 1;
reg clk = 0;
reg ofifo_rd = 0;
reg qmem_rd = 0;
reg qmem_wr = 0; 
reg kmem_rd = 0; 
reg kmem_wr = 0; 
reg pmem_rd = 0; 
reg pmem_wr = 0; 
reg execute = 0;
reg load = 0;
reg [3:0] qkmem_add = 0;
reg [3:0] pmem_add = 0;
reg sfp_acc = 0;
reg sfp_div = 0;
reg pmem_src_sel = 1;
reg kqmem_src_sel = 1;
reg mode = 0;
reg start = 0;

reg ofifo_rd_q = 0;
reg qmem_rd_q = 0;
reg qmem_wr_q = 0; 
reg kmem_rd_q = 0; 
reg kmem_wr_q = 0; 
reg pmem_rd_q = 0; 
reg pmem_wr_q = 0; 
reg execute_q = 0;
reg load_q = 0;
reg [3:0] qkmem_add_q = 0;
reg [3:0] pmem_add_q = 0;
reg sfp_acc_q = 0;
reg sfp_div_q = 0;
reg pmem_src_sel_q = 1;
reg kqmem_src_sel_q = 1;
reg mode_q = 0;
reg start_q = 0;

assign inst[19] = kqmem_src_sel_q;
assign inst[18] = pmem_src_sel_q;
assign inst[17] = sfp_div_q;
assign inst[16] = sfp_acc_q;
assign inst[15] = ofifo_rd_q;
assign inst[14:11] = qkmem_add_q;
assign inst[10:8] = pmem_add_q;
assign inst[7] = execute_q;
assign inst[6] = load_q;
assign inst[5] = qmem_rd_q;
assign inst[4] = qmem_wr_q;
assign inst[3] = kmem_rd_q;
assign inst[2] = kmem_wr_q;
assign inst[1] = pmem_rd_q;
assign inst[0] = pmem_wr_q;

reg [bw_psum-1:0] temp5b;
reg [bw_psum+3:0] temp_sum;
reg [bw_psum*col-1:0] temp16b;

fullchip #(
    .bw(bw),
    .bw_psum(bw_psum),
    .col(col),
    .pr(pr)
) fullchip_instance (
    .core0_mem_in(core0_mem_in),
    .out(out),
    .inst(inst),
    .reset(reset),
    .clk(clk)
);

initial begin
    forever #0.5 clk = ~clk;
end

initial begin
    seed = `SEED;

    $dumpfile("fullchip_tb.vcd");
    $dumpvars(0,fullchip_tb);

    $display("##### Reading qdata.txt #####");
    qk_file = $fopen("./test_data/qdata.txt", "r");

    // Q[time][row]
    for (q=0; q<total_cycle; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            Q[q][j] = captured_data;
        end
    end

    $display("##### Reading vdata.txt #####");
    qk_file = $fopen("./test_data/vdata.txt", "r");

    // V[time][row]
    for (q=0; q<total_cycle; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            V[q][j] = captured_data;
        end
    end

    $display("##### Reading kdata.txt #####");
    qk_file = $fopen("./test_data/kdata.txt", "r");

    // K[col][row]
    for (q=0; q<col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            K[q][j] = captured_data;
        end
    end

    $display("##### Reading norm.txt #####");
    qk_file = $fopen("./test_data/norm.txt", "r");

    // N[col][row]
    for (q=0; q<col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            N[q][j] = captured_data;
        end
    end

    //----------------- Estimated results calculation ---------------------
    // result = K*Q
    // norm_result = norm(K*Q)
    // result2 = N*V

    for (t=0; t<total_cycle; t=t+1) begin
        for (q=0; q<col; q=q+1) begin
            result[t][q] = 0;
            result2[t][q] = 0;
            norm_result[t][q] = 0;
        end
        sum[t] = 0;
        sum2[t] = 0;
    end

    // K*Q calculation
    for (t=0; t<total_cycle; t=t+1) begin
        for (q=0; q<col; q=q+1) begin
            for (k=0; k<pr; k=k+1) begin
                result[t][q] = result[t][q] + Q[t][k] * K[q][k];
            end
            if(result[t][q] < 0)
                sum[t] = sum[t] - result[t][q];
            else
                sum[t] = sum[t] + result[t][q];
        end
    end

    // Norm calculation
    for (t=0; t<total_cycle; t=t+1) begin
        for (q=0; q<col; q=q+1) begin
            if(result[t][q] < 0)
                norm_result[t][q] = (-result[t][q])/(sum[t]/128);
            else
                norm_result[t][q] = (result[t][q])/(sum[t]/128);
        end
    end

    // N*V calculation
    for (t=0; t<total_cycle; t=t+1) begin
        for (q=0; q<col; q=q+1) begin
            for (k=0; k<pr; k=k+1) begin
                result2[t][q] = result2[t][q] + V[t][k] * N[q][k];
            end
        end
    end

    //------------------- QMEM Writing -----------------------------
    $display("##### QMEM Writing  #####");
    for (q=0; q<10; q=q+1) begin
	#1;
    end
    reset = 0;
    #2;
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
    end
    qkmem_add 	= qkmem_add + 1;


    $display("##### Vdata Writing  #####");
    for (q=0; q<total_cycle; q=q+1) begin
	qmem_wr = 1;  
	if (q>0) 
		qkmem_add = qkmem_add + 1; 
	#1;
	core0_mem_in[1*bw-1:0*bw] = V[q][0];
	core0_mem_in[2*bw-1:1*bw] = V[q][1];
	core0_mem_in[3*bw-1:2*bw] = V[q][2];
	core0_mem_in[4*bw-1:3*bw] = V[q][3];
	core0_mem_in[5*bw-1:4*bw] = V[q][4];
	core0_mem_in[6*bw-1:5*bw] = V[q][5];
	core0_mem_in[7*bw-1:6*bw] = V[q][6];
	core0_mem_in[8*bw-1:7*bw] = V[q][7];
    end

    qmem_wr 	= 0; 
    qkmem_add 	= 0;
    #1;

    $display("##### KMEM Writing #####");
    for (q=0; q<col; q=q+1) begin
	kmem_wr = 1; 
	if (q>0) 
		qkmem_add = qkmem_add + 1; 
	#1;  
	core0_mem_in[1*bw-1:0*bw] = K[q][0];
	core0_mem_in[2*bw-1:1*bw] = K[q][1];
	core0_mem_in[3*bw-1:2*bw] = K[q][2];
	core0_mem_in[4*bw-1:3*bw] = K[q][3];
	core0_mem_in[5*bw-1:4*bw] = K[q][4];
	core0_mem_in[6*bw-1:5*bw] = K[q][5];
	core0_mem_in[7*bw-1:6*bw] = K[q][6];
	core0_mem_in[8*bw-1:7*bw] = K[q][7];

    end
    qkmem_add 	= qkmem_add + 1;
    #1;
    kmem_wr     = 0;
    qkmem_add   = 0;
    #6; 


//----------------------  KEYS LOADING ----------------------
$display("##### Keys loading to processor #####");

kmem_rd = 1;
load = 1; 
for (q=0; q<8; q=q+1) begin
	if(q>0)
		qkmem_add = qkmem_add + 1;
	#1;
end

kmem_rd 	= 0; 
qkmem_add 	= 0;
load 		= 0; 
#1;


// -------------- Execution (Query Loading) ------------------
$display("##### Execute (Query) #####");

qmem_rd = 1;
execute = 1; 
for (q=0; q<total_cycle; q=q+1) begin
	if(q>0)
		qkmem_add = qkmem_add + 1;
	#1;
end

qmem_rd 	= 0; 
qkmem_add 	= 0;
load		= 1;
#1;
load 		= 0;
execute 	= 0;
#1;

//----------------- OFIFO Read and Write to PMEM ---------------------

$display("##### Moving OFIFO data to PMEM #####");
#1;
ofifo_rd = 1; 
#1;
pmem_wr = 1; 
for (q=0; q<total_cycle; q=q+1) begin
	if (q>0)
		pmem_add = pmem_add + 1;
	#1;
end

ofifo_rd 	= 0;
#1;
pmem_wr 	= 0; 
pmem_add 	= 0; 
#1;

`ifdef STEP_1
//--------------- PMEM to SFP for Accumulation ------------------------

$display("##### Moving PMEM data to SFP for Accumulation #####");
$display("##### Verifying K*Q values #####\n");

fork
	begin
		pmem_rd = 1; 
		#1;
		sfp_acc = 1;
		for (t=0; t<total_cycle; t=t+1) begin
			if (t>0) begin
				pmem_add = pmem_add + 1;
			end
			#1;
		end
		
		pmem_rd 	= 0; 
		pmem_add	= 0; 
		sfp_acc 	= 0;
		#1;
	end
	begin
		#3;
		for (n=0; n<total_cycle; n=n+1) begin
				for (q=0; q<col; q=q+1) begin
					temp5b = result[n][q];
						temp16b = {temp16b[139:0], temp5b};
				end
			if (temp16b == out) begin
					$display("K*Q matched for cycle%2d: %40h", n, temp16b);
			end
			else begin
				$display("ERROR incorrect K*Q for cycle%2d", n);
					$display("Expected: %40h", temp16b);
					$display("Observed: %40h", out);
			end
			#1;
		end
	end
join

`endif

`ifdef STEP_2
// Need to pull down sfp_acc 1 cycle after PMEM read complete

	pmem_src_sel = 0;
	$display("\n##### Normalization and Writing back to PMEM #####");
	for (q=0; q<total_cycle; q=q+1) begin
		pmem_rd = 1; 
		pmem_wr = 0;
		if (q > 0)
			pmem_add = pmem_add + 1;
		#1;
		sfp_div = 1;
		pmem_rd = 0;
		pmem_wr = 0;
		#1;
		sfp_div = 0;
		#4;
		pmem_wr = 1;
		#1;
	end
	
	pmem_rd 	= 0; 
	pmem_wr 	= 0;
	pmem_add 	= 0;
	sfp_div 	= 0;
	#1;
	
	$display("##### Reading PMEM to verify normalized outputs #####\n");
	pmem_rd 	= 1;
	pmem_add	= 0;
	#1;
	fork
		begin
			for (q=0; q<total_cycle-1; q=q+1) begin
				pmem_add = pmem_add + 1;
				#1;
			end
			
			pmem_rd		= 0;
			pmem_add	= 0;
			#1;
		end
		begin
			#1;
			for (t=0; t<total_cycle; t=t+1) begin
					for (n=0; n<col; n=n+1) begin
						temp5b = norm_result[t][n];
							temp16b = {temp16b[139:0], temp5b};
					end
				if (temp16b == out) begin
						$display("norm(K*Q) matched for cycle%2d: %40h", t, temp16b);
				end
				else begin
					$display("ERROR incorrect norm(K*Q) for cycle%2d", t);
						$display("Expected: %40h", temp16b);
						$display("Observed: %40h", out);
				end
				#1;
			end
		end
	join

`endif

$finish;

end

always @(posedge clk) begin
    ofifo_rd_q      <= ofifo_rd;
    qmem_rd_q       <= qmem_rd;
    qmem_wr_q       <= qmem_wr; 
    kmem_rd_q       <= kmem_rd; 
    kmem_wr_q       <= kmem_wr;
    pmem_rd_q       <= pmem_rd; 
    pmem_wr_q       <= pmem_wr;
    execute_q       <= execute;
    load_q          <= load;
    qkmem_add_q     <= qkmem_add;
    pmem_add_q      <= pmem_add;
    sfp_acc_q       <= sfp_acc;
    sfp_div_q       <= sfp_div;
    pmem_src_sel_q  <= pmem_src_sel;
    kqmem_src_sel_q <= kqmem_src_sel;
    mode_q          <= mode;
    start_q         <= start;
end

endmodule
