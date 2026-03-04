// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

`timescale 1ns/1ps

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
`ifdef DUAL_CORE_EN
      wire [2*bw_psum*col-1:0] out;
      reg [pr*bw-1:0] core1_mem_in; 
`else
      wire [bw_psum*col-1:0] out;
`endif

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
`ifndef DUAL_CORE_EN
reg [bw_psum*col-1:0] temp16b;
`else
reg [2*bw_psum*col-1:0] temp16b;
`endif

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

initial begin
    forever #0.5 clk = ~clk;
end

initial begin

    $dumpfile("fullchip_tb.vcd");
    $dumpvars(0,fullchip_tb);

`ifdef DUAL_CORE_EN
    $display("\n\n------------DUAL_CORE ENABLED---------------\n\n");
`endif

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
	    //$display("V[%0d][%0d] captured data is %d",q,j,captured_data);
            V[q][j] = captured_data;
        end
    end

    $display("##### Reading kdata.txt #####");
    `ifdef DUAL_CORE_EN
    	qk_file = $fopen("./test_data/kdata_core0.txt", "r");
    `else  
        qk_file = $fopen("./test_data/kdata.txt", "r");
    `endif

    // K[col][row]
    for (q=0; q<col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
	    //$display("K[%0d][%0d] captured data is %d",q,j,captured_data);	
            K[q][j] = captured_data;
        end
    end

    `ifdef DUAL_CORE_EN
	$display("##### Reading kdata_core1.txt #####");
	qk_file = $fopen("./test_data/kdata_core1.txt", "r");
	// K[col][row]
	for (q=8; q<2*col; q=q+1) begin
		for (j=0; j<pr; j=j+1) begin
			qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
			//$display("K[%0d][%0d] captured data is %d",q,j,captured_data);
			K[q][j] = captured_data;
		end
	end
    `endif
    
    `ifdef DUAL_CORE_EN
        $display("##### Reading norm_core0.txt #####");
        qk_file = $fopen("./test_data/norm_core0.txt", "r");
    `else
        $display("##### Reading norm.txt #####");
        qk_file = $fopen("./test_data/norm.txt", "r");
    `endif

    // N[col][row]
    for (q=0; q<col; q=q+1) begin
        for (j=0; j<pr; j=j+1) begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
	    //$display("N[%0d][%0d] captured data is %d",q,j,captured_data);	
            N[q][j] = captured_data;
        end
    end

   `ifdef DUAL_CORE_EN
   	$display("##### Reading norm_core1.txt #####");
   	qk_file = $fopen("./test_data/norm_core1.txt", "r");
   	
   	// N[col][row]
   	for (q=8; q<2*col; q=q+1) begin
   		for (j=0; j<pr; j=j+1) begin
   			qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
			//$display("N[%0d][%0d] captured data is %d",q,j,captured_data);
   			N[q][j] = captured_data;
   		end
   	end
   `endif

    //----------------- Estimated results calculation ---------------------
    // result = K*Q
    // norm_result = norm(K*Q)
    // result2 = N*V

    for (t=0; t<total_cycle; t=t+1) begin
  `ifndef DUAL_CORE_EN
	for (q=0; q<col; q=q+1) begin
  `else
	for (q=0; q<2*col; q=q+1) begin
  `endif
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
		//$display("Q[%0d][%0d] = %d, K[%0d][%0d] = %d, result[%0d][%0d] = %d",t,k,Q[t][k],q,k,K[q][k],t,q,result[t][q]);
            end
            if(result[t][q] < 0)
                sum[t] = sum[t] - result[t][q];
            else
                sum[t] = sum[t] + result[t][q];
	    //$display("sum[%0d] = %d",t,sum[t]);
        end
    

	`ifdef DUAL_CORE_EN
	 for (q=col; q<2*col; q=q+1) begin
	 	for (k=0; k<pr; k=k+1) begin
	 		result[t][q] = result[t][q] + Q[t][k] * K[q][k];
	 		//$display("Q[%0d][%0d] = %d, K[%0d][%0d] = %d, result[%0d][%0d] = %d",t,k,Q[t][k],q,k,K[q][k],t,q,result[t][q]);
	 	end
	 	if(result[t][q] < 0)
	 			sum2[t] = sum2[t] - result[t][q];
	 	else
	 			sum2[t] = sum2[t] + result[t][q];
	 	//$display("sum2[%0d] = %d",t,sum2[t]);
	 end
	`endif
     end

// Norm calculation
for (t=0; t<total_cycle; t=t+1) begin
	`ifndef DUAL_CORE_EN
		for (q=0; q<col; q=q+1) begin
		        //$display("sum[%0d] = %0d, sum/128 = %0d",t, sum[t], sum[t]/128);
			if(result[t][q] < 0)
				norm_result[t][q] = (-result[t][q])/(sum[t]/128);
			else
				norm_result[t][q] = (result[t][q])/(sum[t]/128);

			//$display("norm_result[%0d][%0d] = %0d",t,q,norm_result[t][q]);
		end
	`else
		for (q=0; q<2*col; q=q+1) begin
			if(result[t][q] < 0)
				norm_result[t][q] = (-result[t][q])/((sum[t]/128)+(sum2[t]/128));
			else
				norm_result[t][q] = (result[t][q])/((sum[t]/128)+(sum2[t]/128));
		end
	`endif
end

    // N*V calculation
    for (t=0; t<total_cycle; t=t+1) begin
    `ifdef DUAL_CORE_EN
        for (q=0; q<2*col; q=q+1) begin
    `else
        for (q=0; q<col; q=q+1) begin
    `endif 
		for (k=0; k<pr; k=k+1) begin
				result2[t][q] = result2[t][q] + V[t][k] * N[q][k];
				//if(q<col)
				//	result2[t][q] = result2[t][q] + V[t][k] * norm_result[q][k];
				//else
				//	result2[t][q] = result2[t][q] + V[t][k] * norm_result[q-8][k+8];
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
    qkmem_add 	= qkmem_add + 1;

    //NOTE: V data is stored in the same memory as Q, as it will be later used for N*V computation
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
    qkmem_add 	= qkmem_add + 1;
    #1;

//NOTE: The N data is stored in same memory as K, as it will be later used for N*V computation. N is basically stationed same as we stationed K
    $display("##### Norm writing #####");
    
    for (q=0; q<col; q=q+1) begin
    	kmem_wr = 1; 
    	if (q>0) 
    		qkmem_add = qkmem_add + 1; 
    
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

`ifndef DUAL_CORE_EN
	$display("\n\n-----------STEP_1 (SINGLE_CORE)-------------\n\n");
`else 
	$display("\n\n-----------STEP_1 (DUAL_CORE)-------------\n\n");
`endif

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
					$display("K*Q matched for cycle%2d: %80h", n, temp16b);
				`else
					$display("K*Q matched for cycle%2d: %40h", n, temp16b);
				`endif
			end
			else begin
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

`endif

`ifdef STEP_2

`ifndef DUAL_CORE_EN
	$display("\n\n-----------STEP_2 (SINGLE_CORE)-------------\n\n");
`else 
	$display("\n\n-----------STEP_2 (DUAL_CORE)-------------\n\n");
`endif

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
				`ifdef DUAL_CORE_EN
					for (n=0; n<2*col; n=n+1) begin
				`else
					for (n=0; n<col; n=n+1) begin
				`endif	
						temp5b = norm_result[t][n];
						//$display("norm_result");
						`ifdef DUAL_CORE_EN
							temp16b = {temp16b[299:0], temp5b};
						`else
							temp16b = {temp16b[139:0], temp5b};
						`endif
					end
				if (temp16b == out) begin
					`ifdef DUAL_CORE_EN
						$display("norm(K*Q) matched for cycle%2d: %80h", t, temp16b);
					`else
						$display("norm(K*Q) matched for cycle%2d: %40h", t, temp16b);
					`endif
				end
				else begin
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
`endif

`ifdef STEP_4

`ifndef DUAL_CORE_EN
	$display("\n\n-----------STEP_4 (SINGLE_CORE)-------------\n\n");
`else 
	$display("\n\n-----------STEP_4 (DUAL_CORE)-------------\n\n");
`endif

	//----------------------  NORM LOADING ----------------------
	$display("\n##### N loading to processor #####");
	
	qkmem_add = 8; //base addr for N stored in kmem
	kmem_rd = 1;   //start reading out N values
	load = 1; 
	for (q=0; q<col; q=q+1) begin
		if(q>0)
			qkmem_add = qkmem_add + 1;
		#1;
	end
	
	kmem_rd 	= 0; 
	qkmem_add 	= 0;
	load 		= 0; 
	#1;
	
	// -------------- Execution (Value Loading) ------------------
	$display("##### V streaming to processor #####");
	
	qmem_rd = 1;  //start reading from Q memory and streaming to PE
	qkmem_add	= 8; //base addr for V values
	execute = 1; 
	for (q=0; q<total_cycle; q=q+1) begin
		if(q>0)
			qkmem_add = qkmem_add + 1;
		#1;
	end
	
	qmem_rd 	= 0; 
	qkmem_add 	= 0;
	execute 	= 0;
	#2;
	
	//----------------- OFIFO Read and Write to PMEM ---------------------
	
	$display("##### Moving OFIFO data to PMEM #####");
	#1;
	pmem_src_sel = 1;
	ofifo_rd = 1; 
	#1;
	pmem_wr = 1; 
	for (q=0; q<total_cycle; q=q+1) begin
			if(q>0)
			pmem_add = pmem_add + 1;
		#1;
	end
	
	ofifo_rd 	= 0;
	#1;
	pmem_wr 	= 0; 
	pmem_add 	= 0; 
	#1;
	
	$display("##### Reading PMEM to verify N*V outputs #####\n");
	fork
		begin
			for (q=0; q<total_cycle; q=q+1) begin
				pmem_rd = 1;
				if (q>0)
					pmem_add = pmem_add + 1;
				#1;
			end
			
			pmem_rd		= 0;
			pmem_add	= 0;
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
							$display("N*V matched for cycle%2d: %40h", n, temp16b);
					`else
							$display("N*V matched for cycle%2d: %80h", n, temp16b);
					`endif
	
				end
				else begin
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
