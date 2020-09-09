library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simpleram is
port(
	SYSCLK,
	Mem_OE,
	Mem_WR,
	Mod2ModBus:	in		std_logic;
	MemBus:		inout std_logic_vector(7 downto 0);
	ModBus:		out	std_logic_vector(7 downto 0);
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
			tmp(0 to 22) := (
				x"40", x"01",			-- MOV $0x01, A
				x"32", x"03",			-- ADD $0x03, C
				x"B9",					-- ADD C, B
				x"91",					-- SUB A, B
				x"0C", x"FE",			-- JNZ -$0x03
				x"05", x"55", x"44",	-- JZ  0x4455
				x"7E",			-- MOV D, C
				x"C7",			-- ADD B, D
				x"33", x"05",	-- ADD $0x05, D
				x"3E", x"11",	-- OR  $0x11, C
				x"DA",			-- XOR C, C
				x"24", x"03",	-- SUB $0x03, A
				x"97",			-- SUB B, D
				x"C8",			-- ADD C, A
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
	ModBus <= ram(address) when Mod2ModBus = '0' else "ZZZZZZZZ";
	
	process(SYSCLK, address)
	begin
		if(falling_edge(SYSCLK)) then
			address <= to_integer(unsigned(compound));
		end if;
	end process;
	
	process(SYSCLK, Mem_WR)
	begin
		if(rising_edge(SYSCLK) and Mem_WR = '1') then
			ram(address) <= MemBus;
		end if;
	end process;
end arch;
