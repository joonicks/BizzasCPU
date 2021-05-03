library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simpleram is
port(
	SYSCLK,
	Mem_OE,
	Mem_WR:		in		std_logic;
	MemBus:		inout std_logic_vector(7 downto 0);
	addrLo,
	addrHi:		in		unsigned(7 downto 0)
	);
end entity;

architecture arch of simpleram is
	type memory_t is array(0 to 255) of std_logic_vector(7 downto 0);
	function init_ram
		return memory_t is
		variable tmp : memory_t;
		begin
			-- Fibonnachi output register A: 01, 03, 08, 15, 37, 90, 79 (loop)
			--				  output register B: 01, 02, 05, 0D, 22, 59, E9 (loop)
			tmp(0 to 12) := (			-- Fibonnachi
				x"70", x"01",			-- MOV $0x01, A
				x"71",					-- MOV A, B
				x"C1",					-- ADD A, B
				x"C4",					-- ADD B, A
				x"0A", x"FD",			-- JNC -3
				x"01", x"00", x"00", -- NOP 0x0000
				x"00", x"00", x"00"	-- JMP 0x0000
				);
--			tmp(0 to 9) := (			-- Count down from 7
--				x"70", x"01",			-- MOV $0x01, A
--				x"75", x"07",			-- MOV $0x07, B
--				x"91",					-- SUB A, B
--				x"0C", x"FE",			-- JNZ -2
--				x"00", x"00", x"00"	-- JMP 0x0000
--				);
--			tmp(0 to 29) := (			-- Test code
--				x"70", x"01",			-- MOV $0x01, A
--				x"CA", x"06",			-- ADD $0x06, C
--				x"C1",					-- ADD A, B
--				x"89",					-- CMP C, B
--				x"9B",					-- SUB C, D
--				x"AB",					-- SBC C, D
--				x"AB",					-- SBC C, D
--				x"CF", x"15",			-- ADD $0x15, D
--				x"BF", x"05",			-- ADC $0x05, D
--				x"11", x"00", x"00",	-- LD  [0x0000], B
--				x"19", x"02",			-- LD  [0x02], B
--				x"F7",					-- XOR B, D
--				x"FA",					-- XOR C, C
--				x"1F", x"01",			-- ST  D, [0x01]
--				x"23",					-- ST  B, [C:D]
--				x"20",					-- LD  [C:D], A
--				x"00", x"56", x"78",	-- JMP 0x5678
--				x"0B", x"FD",			-- JC  -2
--				x"00" );
		return tmp;
	end init_ram;
	signal address: natural range 0 to 255 := 0;
	signal ram : memory_t := init_ram;
begin
	MemBus <= ram(address) when Mem_OE = '1' else "ZZZZZZZZ";
	
	process(SYSCLK, address, Mem_WR)
		variable compound: unsigned(15 downto 0);
	begin
		if (falling_edge(SYSCLK)) then
			compound(15 downto 8) := addrHi;
			compound( 7 downto 0) := addrLo;
			address <= to_integer(compound);
		end if;
		if (rising_edge(SYSCLK) and Mem_WR = '1') then
			ram(address) <= MemBus;
		end if;
	end process;
end arch;
