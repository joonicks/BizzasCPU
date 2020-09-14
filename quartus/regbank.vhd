library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regbank is
port(
	SYSCLK,
	CD2addr,
	DstBus2Mem,
	Mem2ModBus,
	MemBus2Dst,
	ALUBus2Dst,
	RegCopy:		in		std_logic;
	ModSel,
	DstSel:		in		natural range 0 to 3;--std_logic_vector(1 downto 0);
	ALUBus:		in		std_logic_vector(7 downto 0);
	MemBus:		inout	std_logic_vector(7 downto 0);
	ModBus,
	DstBus,
	addrHi,
	addrLo,
	A, B,
	C,	D:			out	std_logic_vector(7 downto 0)
	);
end regbank;
-- Logic Elements: 36 37 44 36(68) 100
architecture arch of regbank is
type bytebank_t is array(0 to 3) of std_logic_vector(7 downto 0);
signal bytebank: bytebank_t;
begin
	A <= bytebank(0);
	B <= bytebank(1);
	C <= bytebank(2);
	D <= bytebank(3);
	
	process(SYSCLK, ALUBus2Dst, MemBus2Dst, RegCopy, DstSel, ModSel)
	begin
		if (rising_edge(SYSCLK)) then
			if (ALUBus2Dst = '1') then
				bytebank(DstSel) <= ALUBus;
			end if;
			if (MemBus2Dst = '1') then
				bytebank(DstSel) <= MemBus;
			end if;
			if (RegCopy = '1') then
				bytebank(DstSel) <= bytebank(ModSel);
			end if;
		end if;
	end process;

	MemBus <= bytebank(DstSel) when DstBus2Mem = '1' else "ZZZZZZZZ";
	DstBus <= bytebank(DstSel);
	ModBus <= bytebank(ModSel) when Mem2ModBus = '0' else MemBus;
	addrHi <= bytebank(2) when CD2addr = '1' else "ZZZZZZZZ";
	addrLo <= bytebank(3) when CD2addr = '1' else "ZZZZZZZZ";
end arch;
