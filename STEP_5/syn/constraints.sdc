set clock_cycle 1.0
set io_delay    0.1

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay  $io_delay -clock $clock_port [all_inputs]
set_output_delay $io_delay -clock $clock_port [all_outputs]

#false path for async reset:
set_false_path -from [get_ports reset]

#set_multicycle_path 3 -setup -to [get_cells "sfp_instance/sfp_out_sign*_reg\[*\]"]
#set_multicycle_path 2 -hold -to [get_cells "sfp_instance/sfp_out_sign*_reg\[*\]"]

#set_multicycle_path 2 -setup -to [get_cells "sfp_instance/sum_q_reg\[*\]"]
#set_multicycle_path 1 -hold -to [get_cells "sfp_instance/sum_q_reg\[*\]"]

#set_multicycle_path 2 -setup -to [get_cells "ofifo_instance/*/q*_reg\[*\]"]
#set_multicycle_path 1 -hold -to [get_cells "ofifo_instance/*/q*_reg\[*\]"]







