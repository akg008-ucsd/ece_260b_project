# Step 3: SRAM Synthesis -- sram_w8

set top_module sram_w8

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set PROJ_DIR   [file normalize "${SCRIPT_DIR}/../../../"]
set DESIGN_DIR "${PROJ_DIR}/design"

cd $SCRIPT_DIR
# Technology Library
set target_library /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gplustc.db
set link_library   [concat * $target_library]
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true

set compile_effort          "high"
set hdlin_auto_save_templates false
set verilogout_single_bit   false

if {![file exists log]}  { exec mkdir log  }
if {![file exists gate]} { exec mkdir gate }

if {[file exists template_sram_w8]} { exec rm -rf template_sram_w8 }
define_design_lib WORK -path ./template_sram_w8

sh date
sh echo hostname
puts "INFO: SCRIPT_DIR = $SCRIPT_DIR"
puts "INFO: PROJ_DIR   = $PROJ_DIR"
puts "INFO: DESIGN_DIR = $DESIGN_DIR"

# Read RTL 
analyze -format verilog [list ${DESIGN_DIR}/memories/sram_w8.v]

elaborate $top_module
current_design $top_module
link

# Constraints 
read_sdc ${SCRIPT_DIR}/constraints.sdc
propagate_constraints

set_fix_multiple_port_nets -all -buffer_constants
if { [sizeof_collection [all_clocks]] > 0 } {
    set_fix_hold [all_clocks]
}

# Compile
compile_ultra -no_autoungroup -exact_map

# Write Verilog netlist only 
change_names -rules verilog -hierarchy
write -format verilog -hier -output gate/${top_module}.out.v

# Reports
redirect log/${top_module}_area.rep \
    { report_area }
redirect -append log/${top_module}_area.rep \
    { report_reference }
redirect log/${top_module}_timing.rep \
    { report_timing -path full -max_paths 20 -nets \
      -transition_time -capacitance -significant_digits 3 -nosplit }
redirect log/${top_module}_power.rep \
    { report_power }

set unmapped [get_designs -filter "is_unmapped == true" $top_module]
if { [sizeof_collection $unmapped] != 0 } {
    echo "****************************************************"
    echo "* ERROR: Compile finished with unmapped logic.     *"
    echo "****************************************************"
}

sh date
echo "${top_module} synthesis completed."
echo "  Netlist: ${SCRIPT_DIR}/gate/${top_module}.out.v"


