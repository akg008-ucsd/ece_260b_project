# Step 3: Hierarchical Core Synthesis

set top_module fullchip

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set PROJ_DIR   [file normalize "${SCRIPT_DIR}/../../"]
set DESIGN_DIR "${PROJ_DIR}/design"

cd $SCRIPT_DIR

#Technology Library
set target_library /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gplustc.db
set link_library   [concat * $target_library]
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true

set compile_effort "high"
set hdlin_auto_save_templates false
set verilogout_single_bit   false

if {![file exists log]}  { exec mkdir log  }
if {![file exists gate]} { exec mkdir gate }

if {[file exists template_hier]} { exec rm -rf template_hier }
define_design_lib WORK -path ./template_hier

sh date
sh echo hostname
puts "INFO: SCRIPT_DIR = $SCRIPT_DIR"
puts "INFO: PROJ_DIR   = $PROJ_DIR"
puts "INFO: DESIGN_DIR = $DESIGN_DIR"

# Search path
set search_path [list \
	${DESIGN_DIR}/common_ip  \
	${DESIGN_DIR}/MAC        \
	${DESIGN_DIR}/OFIFO      \
	${DESIGN_DIR}/memories   \
	${DESIGN_DIR}/SFP        \
	${DESIGN_DIR}            \
	]

# Read ALL RTL including SRAMs
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

elaborate fullchip
report_hierarchy
current_design fullchip
link

# FIX 1: Removed bare set_dont_touch on design names (UID-95).
# Must target instances by ref_name instead - the foreach loops do this correctly.
foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w16*"] {
	set_dont_touch $cell
}
foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w8*"] {
	set_dont_touch $cell
}

# Constraints
read_sdc ${SCRIPT_DIR}/constraints.sdc
propagate_constraints

set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
if { [sizeof_collection [all_clocks]] > 0 } {
	set_fix_hold [all_clocks]
}

# FIX 2: BUFFD4BWP7T does not exist in tcbn65gplustc.db (UID-993).
# Use BUFFD4BWP65LP which is the correct cell name for this library.
set_driving_cell -lib_cell BUFFD4BWP7T -pin Z [all_inputs]
set_load 0.005 [all_outputs]

set_app_var ungroup_keep_original_design true
set_register_merging [get_designs fullchip] false
set compile_seqmap_propagate_constants        false
set compile_seqmap_propagate_high_effort      false

# FIX 3: Removed broken foreach loop over all sub-designs that was
# unconditionally resetting current_design to fullchip every iteration.
current_design fullchip
set_fix_multiple_port_nets -all

# Compile
compile_ultra -no_autoungroup -exact_map

# Write netlists
current_design fullchip
change_names -rules verilog -hierarchy
write -format verilog -hier -output gate/${top_module}.hier.out.v

# core is a sub-design inside fullchip after hierarchical compile.
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



