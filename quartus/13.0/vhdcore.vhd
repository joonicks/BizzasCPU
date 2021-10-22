library ieee;
use ieee.std_logic_1164.all;

entity vhdcore is
port(
	SYSCLK:			in		std_logic;
	Mem_OE,
	Mem_WR:			buffer std_logic;
	addrLo,
	addrHi,
	MemBus:			inout	std_logic_vector(7 downto 0);
	OutPort,
	A, B, C, D,
	IREG:				out	std_logic_vector(7 downto 0);
	MR:				out	std_logic_vector(15 downto 0)
	);
end vhdcore;

architecture arch of vhdcore is
	signal ALU_Cin, F_Store, F_Carry, F_Zero, F_Sign: std_logic;
	signal PChold, PCjrel: std_logic;
	signal Dst2Mem: std_logic;
	signal AdrSel, Bus2Dst: std_logic_vector(1 downto 0);
	signal ALU_OP, ModSel, DstSel: std_logic_vector(2 downto 0);
	signal ALUBus, ModBus, DstBus: std_logic_vector(7 downto 0);
begin
	control: work.controlunit
	port map(
		SYSCLK		=> SYSCLK,
		F_Carry		=> F_Carry,
		F_Zero		=> F_Zero,
		F_Sign		=> F_Sign,
		Mem_OE		=> Mem_OE,
		Mem_WR		=> Mem_WR,
		PChold		=> PChold,
		PCjrel		=> PCjrel,
		AdrSel		=> AdrSel,
		ModSel		=> ModSel,
		DstSel		=> DstSel,
		Bus2Dst		=> Bus2Dst,
		Dst2Mem		=> Dst2Mem,
		MemBus		=> MemBus,
		ALU_OP		=> ALU_OP,
		ALU_Cin		=> ALU_Cin,
		F_Store		=> F_Store,
		IREG			=> IREG
	);
	
	reg: work.regbank
	port map(
		SYSCLK		=> SYSCLK,
		PChold		=> PChold,
		PCjrel		=> PCjrel,
		Dst2Mem		=> Dst2Mem,
		AdrSel		=> AdrSel,
		ModSel		=> ModSel,
		DstSel		=> DstSel,
		Bus2Dst		=> Bus2Dst,
		ALUBus		=> ALUBus,
		MemBus		=> MemBus,
		ModBus		=> ModBus,
		DstBus		=> DstBus,
		addrLo		=> addrLo,
		addrHi		=> addrHi,
		A				=> A,
		B				=> B,
		C				=> C,
		D				=> D,
		MRDEBUG		=> MR
	);
	
	alu: work.alu8bit
	port map(
		SYSCLK	=> SYSCLK,
		ALU_OP	=> ALU_OP,
		ALU_Cin	=> ALU_Cin,
		F_Store	=> F_Store,
		F_Carry	=> F_Carry,
		F_Zero	=> F_Zero,
		F_Sign	=> F_Sign,
		ALUBus	=> ALUBus,
		ModBus	=> ModBus,
		DstBus	=> DstBus
	);
end arch;