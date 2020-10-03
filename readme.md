# vhdl-teletext

A teletext decoder and display generator in VHDL for FPGAs.

* Level 1.0 decoding and display
* Selected Level 2.5 and Level 3.5 display features implemented
* No vendor-specific code (except dual port RAM, PLL and high-speed I/O buffers)
* Multiple screen resolutions supported
* Small logic size
* Vunit for unit tests (testbenches only completed for some modules so far)
* HDMI output

[Click here to buy the VHDL Teletext PCB on Tindie (fully assembled)](https://www.tindie.com/products/nickelec/fpga-teletext-decoder/) - ships from the UK - please remember that this is a very low volume product so I cannot achieve the low pricing of high-volume consumer gear.

# RTL block diagram

![Block diagram](docs/images/rtl-diagram-shadow.png)

# Implementation

The design runs on the FPGA Teletext board. The PCB includes all the hardware needed to control the teletext decoder and transmit the graphics to the display: FPGA, power supply, programmable oscillator, high-speed comparator, LVDS to TMDS level shifter, keypad, and DIP switches.

![FPGA Teletext PCB](docs/images/fpga-pcb.jpg)

Two oscillators are required for the design: one at 27.750 MHz for teletext decoding and one at whatever frequency is required for the HDMI resolution selected using the DIP switches. The FPGA internal oscillator is used to clock the programmable oscillator controller, required because the programmable oscillator does not generate useful clock frequencies until programmed.

The leftmost DIP switch operates the enhancement data hold function and should normally be left in the up position. When in the up position, enhancement data will be treated as normal. When in the down position, enhancement data will be retained when switching to a different page without enhancement data, allowing enhancements (such as Level 2.5/3.5 colour mapping) to be used on pages that do not originally have these enhancements.

# Programming the FPGA

The MAX10 FPGA is a normal SRAM-based FPGA with an internal configuration flash. Like other Altera FPGAs, it is possible to just program the SRAM without programming the flash, ideal for rapid testing of design modifications, and the design stored in flash is loaded when the board is power-cycled.

To program the FPGA, connect the programmer to J8. Load the POF file (if programming the flash) or SOF file (if only programming the SRAM) into the Quartus Programmer window, tick Program/Configure and Verify, then press Start. Programming the flash will take several seconds but programming the SRAM is instant.

It is possible to store two images in the configuration flash. When configured correctly, J11 can be used to choose which image is used.
