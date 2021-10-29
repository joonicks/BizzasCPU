library ieee;
use ieee.std_logic_1164.all;

entity vhdcore is
port(
	SYSCLK:			in		std_logic;
	Mem_OE,
	Mem_WR:			buffer std_logic;
	PChold,
	PCjrel,
	F_Carry,
	F_Sign,
	F_Zero,
	F_Store,
	Dst2Mem:			buffer std_logic;
	AdrSel,
	Bus2Dst:			out	std_logic_vector(1 downto 0);
	addrLo,
	addrHi:			out	std_logic_vector(7 downto 0);
	MemBus:			inout	std_logic_vector(7 downto 0);
	ALUBus:			out	std_logic_vector(8 downto 0);
	ModBus,
	DstBus:			out	std_logic_vector(7 downto 0);
	A, B, C, D,
	IREG:				out	std_logic_vector(7 downto 0);
	MR:				out	std_logic_vector(15 downto 0)
	);
end vhdcore;

architecture arch of vhdcore is
	signal ALU_Cin: std_logic;
	signal ALU_OP, ModSel, DstSel: std_logic_vector(2 downto 0);
	signal ixAdrSel, ixBus2Dst: std_logic_vector(1 downto 0);
	signal ixALUBus: std_logic_vector(8 downto 0);
	signal ixModBus, ixDstBus: std_logic_vector(7 downto 0);
begin
	ModBus <= ixModBus;
	DstBus <= ixDstBus;
	ALUBus <= ixALUBus;
	AdrSel <= ixAdrSel;
	Bus2Dst <= ixBus2Dst;
	
	control: work.controlunit
	port map(
		SYSCLK		=> SYSCLK,
		Mem_OE		=> Mem_OE,
		Mem_WR		=> Mem_WR,
		PChold		=> PChold,
		PCjrel		=> PCjrel,
		AdrSel		=> ixAdrSel,
		ModSel		=> ModSel,
		DstSel		=> DstSel,
		Bus2Dst		=> ixBus2Dst,
		Dst2Mem		=> Dst2Mem,
		MemBus		=> MemBus,
		ALU_OP		=> ALU_OP,
		ALU_Cin		=> ALU_Cin,
		F_Store		=> F_Store,
		F_Carry		=> F_Carry,
		F_Zero		=> F_Zero,
		F_Sign		=> F_Sign,
		-- debug outputs:
		IREG			=> IREG
	);
	
	reg: work.regbank
	port map(
		SYSCLK		=> SYSCLK,
		PChold		=> PChold,
		PCjrel		=> PCjrel,
		Dst2Mem		=> Dst2Mem,
		AdrSel		=> ixAdrSel,
		ModSel		=> ModSel,
		DstSel		=> DstSel,
		Bus2Dst		=> ixBus2Dst,
		ALUBus		=> ixALUBus,
		F_Store		=> F_Store,
		F_Carry		=> F_Carry,
		F_Zero		=> F_Zero,
		F_Sign		=> F_Sign,
		MemBus		=> MemBus,
		ModBus		=> ixModBus,
		DstBus		=> ixDstBus,
		addrLo		=> addrLo,
		addrHi		=> addrHi,
		-- debug outputs:
		A				=> A,
		B				=> B,
		C				=> C,
		D				=> D,
		MRDEBUG		=> MR
	);
	
	alu: work.alu8bit
	port map(
		ALU_OP	=> ALU_OP,
		ALU_Cin	=> ALU_Cin,
		ALUBus	=> ixALUBus,
		ModBus	=> ixModBus,
		DstBus	=> ixDstBus
	);
end arch;