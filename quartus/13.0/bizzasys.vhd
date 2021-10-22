library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bizzasys is
port(
	SYSCLK:			in			std_logic;
	Mem_OE,
	Mem_WR:			buffer	std_logic;
	addrLo,
	addrHi,
	MemBus,
	OutPort:			inout		std_logic_vector(7 downto 0);
	A, B, C, D,
	IREG:				out		std_logic_vector(7 downto 0);
	MR:				out		std_logic_vector(15 downto 0)
	);
end bizzasys;

architecture arch of bizzasys is
begin
	ram: entity work.simpleram
	port map(
		SYSCLK	=> SYSCLK,
		Mem_OE	=> Mem_OE,
		Mem_WR	=> Mem_WR,
		addrLo	=> addrLo,
		addrHi	=> addrHi,
		MemBus	=> MemBus		
	);
	
	bizzaport: entity work.bizzaport
	port map(
		SYSCLK	=> SYSCLK,
		Mem_OE	=> Mem_OE,
		Mem_WR	=> Mem_WR,
		addrLo	=> addrLo,
		addrHi	=> addrHi,
		MemBus	=> MemBus,
		OutPort	=> OutPort
	);
	
	cpu: entity work.vhdcore
	port map(
		SYSCLK	=> SYSCLK,
		Mem_OE	=> Mem_OE,
		Mem_WR	=> Mem_WR,
		addrLo	=> addrLo,
		addrHi	=> addrHi,
		MemBus	=> MemBus,
		IREG		=> IREG,
		A			=> A,
		B			=> B,
		C			=> C,
		D			=> D,
		MR			=> MR
	);
end arch;