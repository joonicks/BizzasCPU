library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regbank is
port(
	SYSCLK,
	Mod2ModBus,
	ALUBus2Dst:	in		std_logic;
	ModSel,
	DstSel:		in		std_logic_vector(1 downto 0);
	ALUBus:		in		std_logic_vector(7 downto 0);
	ModBus,
	DstBus,
	A, B,
	C,	D:				out	std_logic_vector(7 downto 0)
	);
end regbank;
-- Logic Elements: 36 37 44
architecture arch of regbank is
type bytebank_t is array(0 to 3) of unsigned(7 downto 0);
signal bytebank: bytebank_t;
signal regA, regB, regC, regD: unsigned(7 downto 0);
begin
	A <= std_logic_vector(bytebank(0));
	B <= std_logic_vector(bytebank(1));
	C <= std_logic_vector(bytebank(2));
	D <= std_logic_vector(bytebank(3));
	
	process(SYSCLK, ALUBus2Dst, DstSel)
	begin
		if (rising_edge(SYSCLK) and ALUBus2Dst = '1') then
			bytebank(to_integer(unsigned(DstSel))) <= unsigned(ALUBus);
		end if;
	end process;

	ModBus <= std_logic_vector(bytebank(to_integer(unsigned(ModSel)))) when Mod2ModBus = '1' else "ZZZZZZZZ";
	DstBus <= std_logic_vector(bytebank(to_integer(unsigned(DstSel))));
end arch;
