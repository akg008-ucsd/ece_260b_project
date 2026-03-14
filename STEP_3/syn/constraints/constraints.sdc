set clock_cycle 1.0
set io_delay    0.1

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay  $io_delay -clock $clock_port [all_inputs]
set_output_delay $io_delay -clock $clock_port [all_outputs]

# Drive strength and output load
#set_driving_cell -lib_cell BUFFD4BWP7T -pin Z [all_inputs]
#set_load 0.005 [all_outputs]

#false path for async reset:
set_false_path -from [get_ports reset]
