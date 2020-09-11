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
	addrHi:		in		std_logic_vector(7 downto 0)
	);
end entity;

architecture arch of simpleram is
	type memory_t is array(0 to 255) of std_logic_vector(7 downto 0);
	function init_ram
		return memory_t is
		variable tmp : memory_t;
		begin
			tmp(0 to 25) := (
				x"40", x"01",			-- MOV $0x01, A
				x"32", x"06",			-- ADD $0x06, C
				x"C1",					-- ADD A, B
				x"21", x"06",			-- CMP $0x06, B
				x"9B",					-- SUB C, D
				x"AB",					-- SBC C, D
				x"AB",					-- SBC C, D
				x"33", x"15",			-- ADD $0x15, D
				x"2F", x"05",			-- ADC $0x05, D
				x"11", x"00", x"00",	-- MOV [0x0000], B
				x"19", x"02",			-- MOV [0x00], B
				x"D7",					-- XOR B, D
				x"1E", x"01",			-- MOV A, [0x01]
				x"00", x"56", x"78",	-- JMP 0x5678
				x"00" );
		return tmp;
	end init_ram;
	signal address: natural range 0 to 255;
	signal compound: std_logic_vector(15 downto 0);
	signal ram : memory_t := init_ram;
begin
	compound(15 downto 8) <= addrHi;
	compound (7 downto 0) <= addrLo;
	MemBus <= ram(address) when Mem_OE = '1' else "ZZZZZZZZ";
	
	process(SYSCLK, address)
	begin
		if(falling_edge(SYSCLK)) then
			address <= to_integer(unsigned(compound));
		end if;
	end process;
	process(SYSCLK, address, Mem_WR)
	begin
		if(rising_edge(SYSCLK)and Mem_WR = '1') then
			ram(address) <= MemBus;
		end if;
	end process;
end arch;
