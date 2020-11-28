set_global_assignment -entity "gpio_lite" -library "lib_gpio_lite" -name IP_TOOL_NAME "altera_gpio_lite"
set_global_assignment -entity "gpio_lite" -library "lib_gpio_lite" -name IP_TOOL_VERSION "19.1"
set_global_assignment -entity "gpio_lite" -library "lib_gpio_lite" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_gpio_lite" -name SPD_FILE [file join $::quartus(sip_path) "gpio_lite.spd"]

set_global_assignment -library "lib_gpio_lite" -name MISC_FILE [file join $::quartus(sip_path) "gpio_lite_sim/gpio_lite.vhd"]
set_global_assignment -library "lib_gpio_lite" -name MISC_FILE [file join $::quartus(sip_path) "gpio_lite_sim/altera_gpio_lite/altera_gpio_lite.sv"]
set_global_assignment -library "lib_gpio_lite" -name MISC_FILE [file join $::quartus(sip_path) "gpio_lite_sim/altera_gpio_lite/mentor/altera_gpio_lite.sv"]
