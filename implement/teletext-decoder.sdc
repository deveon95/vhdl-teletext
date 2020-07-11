
create_clock -name {CLK_27_750} -period 36.036 [get_ports {CLK_27_750}]
create_clock -name {CLK_VIDEO} -period 25.00 [get_ports {CLK_VIDEO}]
create_clock -name {int_osc_clk} -period 8.62 [get_pins -compatibility_mode {*oscillator_dut|clkout}]
derive_clock_uncertainty
derive_pll_clocks

# set false path for all ports - used when there are no external synchronous devices
set_false_path -from [get_ports {*}]
set_false_path -to [get_ports {*}]
# set false path for keypad mode select switches because synchronisers have been used in the code
set_false_path -from {KEYPAD:KEYPAD_CONTROLLER|BUTTONS_OUT[13]} -to {SI5351:CLOCK_CONTROLLER|RES_SYNCER}
set_false_path -from {KEYPAD:KEYPAD_CONTROLLER|BUTTONS_OUT[14]} -to {SI5351:CLOCK_CONTROLLER|REF_SYNCER}
set_false_path -from {KEYPAD:KEYPAD_CONTROLLER|BUTTONS_OUT[13]} -to {HDMI:HDMI|RES_SYNCER}

set_false_path -from [get_clocks CLK_27_750] -to [get_clocks CLK_VIDEO]
set_false_path -from [get_clocks CLK_VIDEO] -to [get_clocks CLK_27_750]
set_false_path -from [get_clocks {PLL_HDMI|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {PLL_HDMI|altpll_component|auto_generated|pll1|clk[1]}]
