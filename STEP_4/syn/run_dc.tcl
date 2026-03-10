set top_module fullchip
#set PROJ_DIR "../../"
set DESIGN_DIR "/home/linux/ieng6/ECE260B_WI26_A00/s3goyal/ece_260b_project/design"
set rtlPath "/home/linux/ieng6/ECE260B_WI26_A00/s3goyal/ece_260b_project/design"

# Target library
set target_library /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gplustc.db 

set link_library $target_library
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true

set search_path [concat $rtlPath $search_path]
set link_library [concat * $link_library ]

set synthetic_library {}
set link_path [concat  $link_library $synthetic_library]
set dont_use_cells 1
set dont_use_cell_list ""

remove_design -all
if {[file exists template]} {
	exec rm -rf template
}
exec mkdir template
if {![file exists log]} {
    exec mkdir log
}
if {![file exists gate]} {
	exec mkdir gate
}

sh date
sh echo hostname
sh echo uptime

#Compiler directives
set compile_effort   "high"
set compile_no_new_cells_at_top_level false
set hdlin_enable_vpp true
set hdlin_auto_save_templates false

define_design_lib WORK -path ./template
set verilogout_single_bit false

#set search path for RTL files
set search_path [list \
	${DESIGN_DIR}/common_ip  \
	${DESIGN_DIR}/MAC        \
	${DESIGN_DIR}/OFIFO	 \
	${DESIGN_DIR}/memories	 \
	${DESIGN_DIR}/SFP	 \
	${DESIGN_DIR}		\
	]





# read RTL
analyze -format verilog -define {SYN} [list 	\
	${DESIGN_DIR}/fullchip.v		\
	${DESIGN_DIR}/core.v		\
	${DESIGN_DIR}/common_ip/buffer.v		\
	]

elaborate fullchip
report_hierarchy
current_design fullchip

# Link Design
link

# Default SDC Constraints
read_sdc ./constraints.sdc
propagate_constraints

set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
if { [sizeof_collection [all_clocks]] > 0 } {
    set_fix_hold [all_clocks]
}

set_driving_cell -lib_cell BUFFD4BWP7T -pin Z [all_inputs]
set_load 0.005 [all_outputs]
#foreach_in_collection p [all_outputs] {
#	set_load 0.050 $p
#}

#More compiler directives
set compile_effort   "high"
set_app_var ungroup_keep_original_design true
set_register_merging [get_designs fullchip] false
set compile_seqmap_propagate_constants false
set compile_seqmap_propagate_high_effort false
# More constraints and setup before compile
foreach_in_collection design [ get_designs "*" ] {
	current_design fullchip
	#feedthrough / outputs / constants
	set_fix_multiple_port_nets -all
}
current_design fullchip


# Compile
# Source user compile options
compile_ultra -no_autoungroup -timing_high_effort_script -exact_map

# Write Out Design - Hierarchical
current_design fullchip

change_names -rules verilog -hierarchy

write -format verilog -hier -output [format "%s%s" $top_module .out.v]

# Write Reports
redirect [format "%s%s" log/ $top_module _area.rep] { report_area }
redirect -append [format "%s%s%s" log/ $top_module _area.rep] { report_reference }
redirect [format "%s%s%s" log/ $top_module _power.rep] { report_power }
redirect [format "%s%s%s" log/ $top_module _timing.rep] \
  { report_timing -path full -max_paths 100 -nets -transition_time -capacitance -significant_digits 3 -nosplit}

set inFile  [open log/$top_module\_area.rep]
while { [gets $inFile line]>=0 } {
    if { [regexp {Total cell area:} $line] } {
        set AREA [lindex $line 3]
    }
}
close $inFile
set inFile  [open log/$top_module\_power.rep]
while { [gets $inFile line]>=0 } {
    if { [regexp {Total Dynamic Power} $line] } {
        set PWR [lindex $line 4]
    } elseif { [regexp {Cell Leakage Power} $line] } {  
        set LEAK [lindex $line 4] 
    }
}
close $inFile

set unmapped_designs [get_designs -filter "is_unmapped == true" $top_module]
if {  [sizeof_collection $unmapped_designs] != 0 } {
	echo "****************************************************"
	echo "* ERROR!!!! Compile finished with unmapped logic.  *"
	echo "****************************************************"
}
# Done
sh date
sh uptime

# Done
echo "run.scr completed successfully"

