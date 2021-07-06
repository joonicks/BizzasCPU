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
	constant MemoryBytes : integer := 1024;
	type memory_t is array(0 to MemoryBytes-1) of std_logic_vector(7 downto 0);
	function init_ram
		return memory_t is
		variable tmp : memory_t;
		begin
			-- Fibonnachi output register A: 01, 03, 08, 15, 37, 90, 79 (loop)
			--				  output register B: 01, 02, 05, 0D, 22, 59, E9 (loop)
			tmp(0 to 255) := (		-- Fibonnachi
				x"F0", x"01",			-- MOV $0x01, A
				x"F1",					-- MOV A, B
				x"81",					-- ADD A, B
				x"84",					-- ADD B, A
				x"0A", x"FD",			-- JNC -3
				x"8F", x"06",			-- ADD $06, D
				x"CF", x"17",			-- CMP $17, D
				x"01", x"99", x"00", -- NOP 0x0000
				x"6B",					-- INC D
				x"6E",					-- DEC C
				x"2E", x"00",			-- LD  [$00:D], C
				x"12", x"0C", x"00",	-- LD  [$000C], C
				x"6A",					-- INC C
				x"16", x"0C", x"00",	-- ST  C, [$000C]
				x"16", x"77", x"D0", -- ST  C, [$D077]
				x"00", x"00", x"00",	-- JMP 0x0000
				others => x"00");
--			tmp(0 to 255) := (		-- Count down from 7
--				x"70", x"01",			-- MOV $0x01, A
--				x"75", x"07",			-- MOV $0x07, B
--				x"91",					-- SUB A, B
--				x"0C", x"FE",			-- JNZ -2
--				x"00", x"00", x"00",	-- JMP 0x0000
--				others => x"00");
--			tmp(0 to 255) := (		-- Test code
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
--				x"00", x"78", x"56",	-- JMP 0x5678
--				others => x"00");
			tmp(256 to MemoryBytes-1) := (
				others => x"00");
		return tmp;
	end init_ram;
	signal address: natural range 0 to MemoryBytes-1 := 0;
	signal ram : memory_t := init_ram;
begin
	MemBus <= "ZZZZZZZZ" when Mem_OE = '0' else ram(address);
	
	process(SYSCLK, address, ram, Mem_WR)
	begin
		if (falling_edge(SYSCLK)) then
			address <= to_integer(addrHi & addrLo);
		end if;
		if (rising_edge(SYSCLK) and Mem_WR = '1') then
			ram(address) <= MemBus;
		end if;
	end process;
end arch;
