# SRAM constraints for sram_w16
set clock_cycle 3.0
set io_delay    0.1

create_clock -name CLK -period $clock_cycle [get_ports CLK]

# Apply input delay only to non-clock data inputs
set_input_delay  $io_delay -clock CLK [get_ports {D A CEN WEN}]
set_output_delay $io_delay -clock CLK [get_ports Q]

set_driving_cell -lib_cell BUFFD4BWP7T -pin Z [get_ports {D A CEN WEN}]
set_load 0.005 [get_ports Q]

