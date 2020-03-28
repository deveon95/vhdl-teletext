
create_clock -name {CLK_27_750} -period 36.036 [get_ports {CLK_27_750}]
derive_clock_uncertainty

#set_false_path -from [get_ports {RX_IN}] -to [get_registers {DATA_RECOVERY/RX_SYNCED}]
set_false_path -from [get_pins *] -to [get_pins *]