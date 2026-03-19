# Step 6 Hierarchical Synthesis fullchip with SPARSITY_AWARE + DUAL_CORE_EN
set top_module fullchip

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set PROJ_DIR   [file normalize "${SCRIPT_DIR}/../../"]
set DESIGN_DIR "${PROJ_DIR}/design"
set TARGET_DIR "${PROJ_DIR}/target"

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

if {[file exists template_fullchip]} { exec rm -rf template_fullchip }
if {[file exists work]}              { exec rm -rf work }
if {[file exists WORK]}              { exec rm -rf WORK }
define_design_lib WORK -path ./template_fullchip

sh date
sh echo hostname
puts "INFO: SCRIPT_DIR= $SCRIPT_DIR"
puts "INFO: PROJ_DIR= $PROJ_DIR"
puts "INFO: DESIGN_DIR= $DESIGN_DIR"

set search_path [list \
    ${TARGET_DIR}            \
    ${DESIGN_DIR}/common_ip  \
    ${DESIGN_DIR}/MAC        \
    ${DESIGN_DIR}/OFIFO      \
    ${DESIGN_DIR}/memories   \
    ${DESIGN_DIR}/SFP        \
    ${DESIGN_DIR}/ASYNC_FIFO \
    ${DESIGN_DIR}            \
]

analyze -format verilog -define { \
    CLK_GATE \
    STEP_1 \
    STEP_2 \
    STEP_4 \
    STEP_5_DUAL_PORT \
    DUAL_CORE_EN \
    SPARSITY_AWARE \
} [list \
    ${TARGET_DIR}/target_defines.v                  \
    ${DESIGN_DIR}/memories/sram_w16.v               \
    ${DESIGN_DIR}/memories/sram_w8.v                \
    ${DESIGN_DIR}/common_ip/fifo_mux_2_1.v          \
    ${DESIGN_DIR}/common_ip/fifo_mux_8_1.v          \
    ${DESIGN_DIR}/common_ip/fifo_mux_16_1.v         \
    ${DESIGN_DIR}/common_ip/fifo_depth16.v          \
    ${DESIGN_DIR}/common_ip/ofifo_depth16.v         \
    ${DESIGN_DIR}/common_ip/sync.v                  \
    ${DESIGN_DIR}/common_ip/buffer.v                \
    ${DESIGN_DIR}/ASYNC_FIFO/async_rd_fifo.v        \
    ${DESIGN_DIR}/ASYNC_FIFO/async_wr_fifo.v        \
    ${DESIGN_DIR}/ASYNC_FIFO/async_fifo.v           \
    ${DESIGN_DIR}/MAC/mac_16in.v                    \
    ${DESIGN_DIR}/MAC/mac_col.v                     \
    ${DESIGN_DIR}/MAC/mac_array.v                   \
    ${DESIGN_DIR}/OFIFO/ofifo.v                     \
    ${DESIGN_DIR}/SFP/sfp_row.v                     \
    ${DESIGN_DIR}/core.v                            \
    ${DESIGN_DIR}/fullchip.v                        \
]

elaborate fullchip
current_design fullchip
link

# Verify defines
set core1_port [get_ports "core1_mem_in*"]
if { [sizeof_collection $core1_port] > 0 } {
    echo "INFO: DUAL_CORE_EN active"
} else {
    echo "ERROR: DUAL_CORE_EN NOT active"
}

# Mark SRAMs dont_touch
foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w16*"] {
    set_dont_touch $cell
}
foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ sram_w8*"] {
    set_dont_touch $cell
}

# Constraints all applied at fullchip scope
current_design fullchip

set clock_cycle 1.0
set io_delay    0.1
create_clock -name clk -period $clock_cycle [get_ports clk]
set_input_delay  $io_delay -clock clk [all_inputs]
set_output_delay $io_delay -clock clk [all_outputs]
set_false_path -from [get_ports reset]

# CDC false path: async_fifo paths cross from one core's clock domain
# to the other. These are handled by synchronizers inside async_fifo.
# False path the async_fifo cells to prevent spurious violations.
set_false_path -through [get_cells "async_fifo_core_01"]
set_false_path -through [get_cells "async_fifo_core_10"]

propagate_constraints

# MCP: applied at fullchip scope using get_cells bracket
# Core instance0 MCPs
set c0_sfp  [get_cells "core_instance0/sfp_instance/sfp_out_sign*_reg\[*\]"]
set c0_sumq [get_cells "core_instance0/sfp_instance/sum_q_reg\[*\]"]
set c0_ofifo [get_cells "core_instance0/ofifo_instance/col_idx_*__ofifo_instance/q*_reg\[*\]"]

# Core instance1 MCPs  
set c1_sfp  [get_cells "core_instance1/sfp_instance/sfp_out_sign*_reg\[*\]"]
set c1_sumq [get_cells "core_instance1/sfp_instance/sum_q_reg\[*\]"]
set c1_ofifo [get_cells "core_instance1/ofifo_instance/col_idx_*__ofifo_instance/q*_reg\[*\]"]

echo "INFO: c0 sfp_out_sign = [sizeof_collection $c0_sfp]  (expect 160)"
echo "INFO: c1 sfp_out_sign = [sizeof_collection $c1_sfp]  (expect 160)"
echo "INFO: c0 sum_q= [sizeof_collection $c0_sumq]  (expect 24)"
echo "INFO: c1 sum_q= [sizeof_collection $c1_sumq]  (expect 24)"
echo "INFO: c0 ofifo= [sizeof_collection $c0_ofifo]  (expect >0)"
echo "INFO: c1 ofifo= [sizeof_collection $c1_ofifo]  (expect >0)"

# Apply MCPs only if collection is non-empty
foreach {tag coll mult} [list \
    "c0_sfp_A"   $c0_sfp   3 \
    "c1_sfp_A"   $c1_sfp   3 \
    "c0_sumq_B"  $c0_sumq  2 \
    "c1_sumq_B"  $c1_sumq  2 \
    "c0_ofifo_C" $c0_ofifo 2 \
    "c1_ofifo_C" $c1_ofifo 2 \
] {
    if { [sizeof_collection $coll] > 0 } {
        set hold [expr {$mult - 1}]
        set_multicycle_path $mult -setup -to $coll
        set_multicycle_path $hold -hold  -to $coll
        echo "INFO: Applied MCP=$mult $tag ([sizeof_collection $coll] cells)"
    } else {
        echo "WARNING: $tag empty MCP not applied"
    }
}

if { [sizeof_collection $c0_sfp] > 0 } {
    set test_ep [index_collection $c0_sfp 0]
    set tp [get_timing_paths -to $test_ep -delay_type max -nworst 1]
    if { [sizeof_collection $tp] > 0 } {
        set req [get_attribute $tp data_required_time]
        echo "INFO: c0 sfp required_time = $req  (expect ~2.94 for MCP=3, ~0.95 = FAIL)"
        if { $req < 1.5 } {
            echo "ERROR: Compile will fail. Check DC version constraints."
        }
    }
}

set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
set_load 0.005 [all_outputs]

set_app_var ungroup_keep_original_design true
set_register_merging [get_designs fullchip] false
set compile_seqmap_propagate_constants        false
set compile_seqmap_propagate_high_effort      false

compile_ultra -no_autoungroup -exact_map

current_design fullchip
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

sh grep "multicycle" gate/fullchip.sdc || echo "(MCPs at sub-design scope - not in top SDC)"
sh grep "core_instance" gate/fullchip.hier.out.v || echo "(check netlist manually)"

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
echo "Fullchip synthesis completed."
echo "  Area   : $AREA"
echo "  Power  : $PWR  (Leakage: $LEAK)"
echo "  Netlist: ${SCRIPT_DIR}/gate/fullchip.hier.out.v"



