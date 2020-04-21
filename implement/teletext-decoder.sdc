
create_clock -name {CLK_27_750} -period 36.036 [get_ports {CLK_27_750}]
create_clock -name {CLK_VIDEO} -period 31.250 [get_ports {CLK_VIDEO}]
derive_clock_uncertainty

# set false path for all ports - used when there are no external synchronous devices
set_false_path -from [get_ports {*}]
set_false_path -to [get_ports {*}]

set_false_path -from [get_clocks CLK_27_750] -to [get_clocks CLK_VIDEO]
set_false_path -from [get_clocks CLK_VIDEO] -to [get_clocks CLK_27_750]
