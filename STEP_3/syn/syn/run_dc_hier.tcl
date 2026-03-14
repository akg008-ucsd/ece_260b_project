# Step 3: Hierarchical Core Synthesis

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

set top_module core
=======
set top_module fullchip
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl


set SCRIPT_DIR [file normalize [file dirname [info script]]]
set PROJ_DIR   [file normalize "${SCRIPT_DIR}/../../"]
set DESIGN_DIR "${PROJ_DIR}/design"

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

cd $SCRIPT_DIR


set target_library [list \
    /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gplustc.db \
]
set link_library [concat * $target_library]
=======
cd $SCRIPT_DIR

#Technology Library
set target_library /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gplustc.db
set link_library   [concat * $target_library]
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

=======
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
set compile_effort "high"
set hdlin_auto_save_templates false
set verilogout_single_bit   false


if {![file exists log]}  { exec mkdir log  }
if {![file exists gate]} { exec mkdir gate }

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

if {[file exists template_core]} { exec rm -rf template_core }
define_design_lib WORK -path ./template_core
=======
if {[file exists template_hier]} { exec rm -rf template_hier }
define_design_lib WORK -path ./template_hier
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl


sh date
sh echo hostname
puts "INFO: SCRIPT_DIR = $SCRIPT_DIR"
puts "INFO: PROJ_DIR   = $PROJ_DIR"
puts "INFO: DESIGN_DIR = $DESIGN_DIR"

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

=======
# Search path
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
set search_path [list \
	${DESIGN_DIR}/common_ip  \
	${DESIGN_DIR}/MAC        \
	${DESIGN_DIR}/OFIFO      \
	${DESIGN_DIR}/memories   \
	${DESIGN_DIR}/SFP        \
	${DESIGN_DIR}            \
	]

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

=======
# Read ALL RTL including SRAMs
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
analyze -format verilog -define {SYN} [list    \
	${DESIGN_DIR}/memories/sram_w16.v           \
	${DESIGN_DIR}/memories/sram_w8.v            \
	${DESIGN_DIR}/common_ip/fifo_mux_2_1.v      \
	${DESIGN_DIR}/common_ip/fifo_mux_8_1.v      \
	${DESIGN_DIR}/common_ip/fifo_mux_16_1.v     \
	${DESIGN_DIR}/common_ip/fifo_depth16.v      \
	${DESIGN_DIR}/common_ip/ofifo_depth16.v     \
	${DESIGN_DIR}/common_ip/sync.v              \
	${DESIGN_DIR}/common_ip/buffer.v            \
	${DESIGN_DIR}/MAC/mac_16in.v                \
	${DESIGN_DIR}/MAC/mac_col.v                 \
	${DESIGN_DIR}/MAC/mac_array.v               \
	${DESIGN_DIR}/OFIFO/ofifo.v                 \
	${DESIGN_DIR}/SFP/sfp_row.v                 \
	${DESIGN_DIR}/core.v                        \
	${DESIGN_DIR}/fullchip.v                    \
	]

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

elaborate core
current_design core
=======
elaborate fullchip
report_hierarchy
current_design fullchip
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
link


foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w16*"] {
	set_dont_touch $cell
}
foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w8*"] {
	set_dont_touch $cell
}

<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl

# Read constraints (includes MCP via get_cells instance names)
=======
# Constraints
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
read_sdc ${SCRIPT_DIR}/constraints.sdc
propagate_constraints


# Verify MCP targets resolved post-elaborate
set sfp_mcp_cells [get_cells "sfp_instance/sfp_out_sign*_reg\[*\]"]
set sumq_mcp_cells [get_cells "sfp_instance/sum_q_reg\[*\]"]
echo "INFO: sfp_out_sign MCP cells = [sizeof_collection $sfp_mcp_cells]  (expect 160)"
echo "INFO: sum_q MCP cells        = [sizeof_collection $sumq_mcp_cells]  (expect 24)"
if { [sizeof_collection $sfp_mcp_cells] == 0 } {
    echo "ERROR: sfp_out_sign cells not found MCP will NOT apply"
}
if { [sizeof_collection $sumq_mcp_cells] == 0 } {
    echo "ERROR: sum_q cells not found MCP will NOT apply"
}


set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl
=======
if { [sizeof_collection [all_clocks]] > 0 } {
	set_fix_hold [all_clocks]
}

set_driving_cell -lib_cell BUFFD4BWP7T -pin Z [all_inputs]
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
set_load 0.005 [all_outputs]


set_app_var ungroup_keep_original_design true
<<<<<<< HEAD:STEP_3/syn/syn/run_dc_hier.tcl
set_register_merging [get_designs core] false
set compile_seqmap_propagate_constants false
set compile_seqmap_propagate_high_effort false


compile_ultra -no_autoungroup -exact_map


current_design core
change_names -rules verilog -hierarchy
write -format verilog -hier -output gate/${top_module}.hier.out.v
write -format ddc      -hier -output gate/${top_module}.ddc
write_sdc gate/${top_module}.sdc


redirect log/${top_module}_area.rep    { report_area -hierarchy }
redirect -append log/${top_module}_area.rep { report_reference }
redirect log/${top_module}_timing.rep  \
    { report_timing -path full -max_paths 100 -nets \
      -transition_time -capacitance -significant_digits 3 -nosplit }
redirect log/${top_module}_power.rep   { report_power }


# Confirm MCPs persisted ¿ if this prints nothing, constraints still not landing
echo "INFO: MCP lines in gate/core.sdc:"
sh grep "multicycle" gate/core.sdc


=======
set_register_merging [get_designs fullchip] false
set compile_seqmap_propagate_constants        false
set compile_seqmap_propagate_high_effort      false

current_design fullchip
set_fix_multiple_port_nets -all

# Compile
compile_ultra -no_autoungroup -exact_map

# Write netlists
current_design fullchip
change_names -rules verilog -hierarchy
write -format verilog -hier -output gate/${top_module}.hier.out.v

# Check if DC has it in memory; if so write it, otherwise skip gracefully.
if { [sizeof_collection [get_designs -quiet core]] > 0 } {
	current_design core
	write -format verilog -hier -output gate/core.hier.out.v
	current_design fullchip
} else {
	echo "INFO: Design 'core' not found as standalone - skipping core.hier.out.v"
	echo "INFO: Full hierarchy is already captured in gate/${top_module}.hier.out.v"
}

current_design fullchip

# Reports
redirect log/${top_module}_area.rep \
	{ report_area -hierarchy }
redirect -append log/${top_module}_area.rep \
	{ report_reference }
redirect log/${top_module}_timing.rep \
	{ report_timing -path full -max_paths 100 -nets \
	  -transition_time -capacitance -significant_digits 3 -nosplit }
redirect log/${top_module}_power.rep \
	{ report_power }

# Summary
>>>>>>> parent of 7ed0f97 (step 3 top level synth complete):STEP_3/syn/run_dc_hier.tcl
set inFile [open log/${top_module}_area.rep]
while { [gets $inFile line] >= 0 } {
	if { [regexp {Total cell area:} $line] } { set AREA [lindex $line 3] }
}
close $inFile


set inFile [open log/${top_module}_power.rep]
while { [gets $inFile line] >= 0 } {
	if { [regexp {Total Dynamic Power} $line] } { set PWR  [lindex $line 4] }
	if { [regexp {Cell Leakage Power}  $line] } { set LEAK [lindex $line 4] }
}
close $inFile


set unmapped [get_designs -filter "is_unmapped == true" $top_module]
if { [sizeof_collection $unmapped] != 0 } {
	echo "****************************************************"
	echo "* ERROR: Compile finished with unmapped logic.     *"
	echo "****************************************************"
}


sh date
sh uptime
echo "Step 3 hierarchical synthesis completed."
echo "  Area   : $AREA"
echo "  Power  : $PWR  (Leakage: $LEAK)"
echo "  Netlist: ${SCRIPT_DIR}/gate/fullchip.hier.out.v"







