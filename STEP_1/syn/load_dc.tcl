set top_module core

set target_library /home/linux/ieng6/ee260bwi25/public/PDKdata/db/tcbn65gpluswc.db 
set link_library $target_library

read_verilog -netlist "./output/$top_module.out.v"
current_design $top_module

read_sdc "./constraints/$top_module.sdc"

link

list_designs

current_design $top_module

report_timing

