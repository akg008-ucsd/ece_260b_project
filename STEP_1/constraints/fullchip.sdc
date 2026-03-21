
set clock_cycle 2.0 
set io_delay 0.1 

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay  $io_delay -clock $clock_port [all_inputs] 
set_output_delay $io_delay -clock $clock_port [all_outputs]

#false path for async reset:
set_false_path -from [get_ports reset]

#drive strength of primary inputs
#set_driving_cell -lib_cell BUFFD4BWP7T [all_inputs]

#set load capacitance of 5pF
set_load -0.005 [all_outputs]

#max fanout for synthesis optimization
set_max_fanout 20 [current_design]

