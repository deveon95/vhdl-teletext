from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("src/rtl/*.vhd")
lib.add_source_files("src/behave/*.vhd")

#lib.add_compile_option("activehdl.vcom_flags", ["-2008"])

# Run vunit function
vu.main()
