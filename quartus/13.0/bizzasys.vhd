library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bizzasys is
port(
	SYSCLK:			in			std_logic;
	Mem_OE,
	Mem_WR:			out		std_logic;
	PChold,
	PCjrel,
	F_Carry,
	F_Sign,
	F_Zero,
	F_Store,
	Dst2Mem:			out		std_logic;
	AdrSel,
	Bus2Dst:			out	std_logic_vector(1 downto 0);
	addrLo,
	addrHi:			out		std_logic_vector(7 downto 0);
	MemBus:			out		std_logic_vector(7 downto 0);
	ModBus:			out		std_logic_vector(7 downto 0);
	ALUBus:			out		std_logic_vector(8 downto 0);
	OutPort:			out		std_logic_vector(7 downto 0);
	A, B, C, D,
	IREG:				out		std_logic_vector(7 downto 0);
	MR:				out		std_logic_vector(15 downto 0)
	);
end bizzasys;

architecture arch of bizzasys is
signal ixMemBus: std_logic_vector(7 downto 0);
signal ixaddrLo, ixaddrHi: std_logic_vector(7 downto 0);
signal ixMem_OE, ixMem_WR: std_logic;
begin
	MemBus <= ixMemBus;
	Mem_OE <= ixMem_OE;
	Mem_WR <= ixMem_WR;
	addrLo <= ixaddrLo;
	addrHi <= ixaddrHi;

	ram: entity work.simpleram
	port map(
		SYSCLK	=> SYSCLK,
		Mem_OE	=> ixMem_OE,
		Mem_WR	=> ixMem_WR,
		addrLo	=> ixaddrLo,
		addrHi	=> ixaddrHi,
		MemBus	=> ixMemBus		
	);
	
	bizzaport: entity work.bizzaport
	port map(
		SYSCLK	=> SYSCLK,
		Mem_OE	=> ixMem_OE,
		Mem_WR	=> ixMem_WR,
		addrLo	=> ixaddrLo,
		addrHi	=> ixaddrHi,
		MemBus	=> ixMemBus,
		OutPort	=> OutPort
	);
	
	cpu: entity work.vhdcore
	port map(
		SYSCLK	=> SYSCLK,
		Mem_OE	=> ixMem_OE,
		Mem_WR	=> ixMem_WR,
		addrLo	=> ixaddrLo,
		addrHi	=> ixaddrHi,
		MemBus	=> ixMemBus,
		-- debug outputs:
		AdrSel	=> AdrSel,
		Bus2Dst	=> Bus2Dst,
		ModBus	=> ModBus,
		ALUBus	=> ALUBus,
		PChold	=> PChold,
		PCjrel	=> PCjrel,
		F_Carry	=> F_Carry,
		F_Sign	=> F_Sign,
		F_Zero	=> F_Zero,
		F_Store	=> F_Store,
		Dst2Mem	=> Dst2Mem,
		IREG		=> IREG,
		A			=> A,
		B			=> B,
		C			=> C,
		D			=> D,
		MR			=> MR
	);
end arch;