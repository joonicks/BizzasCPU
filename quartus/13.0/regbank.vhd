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
	ModBus2Dst:		in		std_logic;
	ModSel,
	DstSel:		in		natural range 0 to 3;
	ALUBus:		in		std_logic_vector(7 downto 0);
	MemBus,
	ModBus:		inout	std_logic_vector(7 downto 0);
	DstBus,
	addrHi,
	addrLo,
	A, B,
	C,	D:			out	std_logic_vector(7 downto 0)
	);
end regbank;

-- Logic Elements: 36 37 44 36(68) 100 97 94

architecture arch of regbank is
type bytebank_t is array(0 to 3) of std_logic_vector(7 downto 0);
signal bytebank: bytebank_t;
signal tempHi, tempLo: std_logic_vector(7 downto 0);
begin	
	process(SYSCLK, ALUBus2Dst, MemBus2Dst, ModBus2Dst, DstSel, ModSel)
		variable data: std_logic_vector(7 downto 0);
	begin
		if (rising_edge(SYSCLK)) then
			if (ALUBus2Dst = '1') then
				data := ALUBus;
			elsif (MemBus2Dst = '1') then
				data := MemBus;
			elsif (ModBus2Dst = '1') then
				data := ModBus;
			end if;
			
			if (ALUBus2Dst = '1' or MemBus2Dst = '1' or ModBus2Dst = '1') then
				case DstSel is
					when 0 =>
						bytebank(0) <= data;
						A <= data;
					when 1 =>
						bytebank(1) <= data;
						B <= data;
					when 2 =>
						bytebank(2) <= data;
						tempHi <= data;
						C <= data;
					when 3 =>
						bytebank(3) <= data;
						tempLo <= data;
						D <= data;
				end case;
			end if;
		end if;
	end process;
	
	DstBus <= bytebank(DstSel);
	MemBus <= bytebank(DstSel) when DstBus2Mem = '1' else "ZZZZZZZZ";
	ModBus <= bytebank(ModSel) when Mem2ModBus = '0' else MemBus;
	addrHi <= tempHi when CD2addr = '1' else "ZZZZZZZZ";
	addrLo <= tempLo when CD2addr = '1' else "ZZZZZZZZ";
end arch;
