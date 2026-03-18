# Step 3 Hierarchical synthesis


set top_module core


set SCRIPT_DIR [file normalize [file dirname [info script]]]
set PROJ_DIR   [file normalize "${SCRIPT_DIR}/../../"]
set DESIGN_DIR "${PROJ_DIR}/design"


cd $SCRIPT_DIR


set target_library [list \
    /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gplustc.db \
]
set link_library [concat * $target_library]
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true


set compile_effort "high"
set hdlin_auto_save_templates false
set verilogout_single_bit false


if {![file exists log]}  { exec mkdir log  }
if {![file exists gate]} { exec mkdir gate }


if {[file exists template_core]} { exec rm -rf template_core }
define_design_lib WORK -path ./template_core


sh date
sh echo hostname
puts "INFO: SCRIPT_DIR  = $SCRIPT_DIR"
puts "INFO: PROJ_DIR    = $PROJ_DIR"
puts "INFO: DESIGN_DIR  = $DESIGN_DIR"


set search_path [list \
    ${DESIGN_DIR}/common_ip  \
    ${DESIGN_DIR}/MAC        \
    ${DESIGN_DIR}/OFIFO      \
    ${DESIGN_DIR}/memories   \
    ${DESIGN_DIR}/SFP        \
    ${DESIGN_DIR}            \
]


analyze -format verilog -define {SYN} [list    \
    ${DESIGN_DIR}/memories/sram_w16.v          \
    ${DESIGN_DIR}/memories/sram_w8.v           \
    ${DESIGN_DIR}/common_ip/fifo_mux_2_1.v     \
    ${DESIGN_DIR}/common_ip/fifo_mux_8_1.v     \
    ${DESIGN_DIR}/common_ip/fifo_mux_16_1.v    \
    ${DESIGN_DIR}/common_ip/fifo_depth16.v     \
    ${DESIGN_DIR}/common_ip/ofifo_depth16.v    \
    ${DESIGN_DIR}/common_ip/sync.v             \
    ${DESIGN_DIR}/common_ip/buffer.v           \
    ${DESIGN_DIR}/MAC/mac_16in.v               \
    ${DESIGN_DIR}/MAC/mac_col.v                \
    ${DESIGN_DIR}/MAC/mac_array.v              \
    ${DESIGN_DIR}/OFIFO/ofifo.v                \
    ${DESIGN_DIR}/SFP/sfp_row.v                \
    ${DESIGN_DIR}/core.v                       \
]


elaborate core
current_design core
link


foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w16*"] {
    set_dont_touch $cell
}
foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w8*"] {
    set_dont_touch $cell
}


# Read constraints (includes MCP via get_cells instance names)
read_sdc ${SCRIPT_DIR}/constraints.sdc
propagate_constraints


set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
set_load 0.005 [all_outputs]


set_app_var ungroup_keep_original_design true
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
echo "Core synthesis completed."
echo "  Area   : $AREA"
echo "  Power  : $PWR  (Leakage: $LEAK)"
echo "  Netlist: ${SCRIPT_DIR}/gate/core.hier.out.v"






