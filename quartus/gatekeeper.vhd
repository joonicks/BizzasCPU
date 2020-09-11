library ieee;
use ieee.std_logic_1164.all;

entity gatekeeper is
port(
	ALUBus2Mem,
	Mod2ModBus:	in		std_logic;
	MemBus:		inout std_logic_vector(7 downto 0);
	ModBus:		out	std_logic_vector(7 downto 0);
	DstBus:		in		std_logic_vector(7 downto 0));
end entity;

architecture arch of gatekeeper is
begin
	ModBus <= MemBus when Mod2ModBus = '0' else "ZZZZZZZZ";
	MemBus <= DstBus when ALUBus2Mem = '1' else "ZZZZZZZZ";
end arch;