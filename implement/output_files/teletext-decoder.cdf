/* Quartus Prime Version 19.1.0 Build 670 09/22/2019 Patches 0.02std SJ Lite Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(10CL025YU256) Path("Z:/Documents/Projects/Teletext-decoder/fpga/implement/output_files/") File("teletext-decoder.sof") MfrSpec(OpMask(1));
	P ActionCode(Ign)
		Device PartName(VTAP10) MfrSpec(OpMask(0));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
