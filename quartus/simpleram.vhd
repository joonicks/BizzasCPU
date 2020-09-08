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
	type memory_t is array(255 downto 0) of std_logic_vector(7 downto 0);

	function init_ram
		return memory_t is
		variable tmp : memory_t := (others => (others => '0'));
		begin
			tmp(0)  := x"40"; -- MOV IMM8, A
			tmp(1)  := x"99"; -- IMM8
			tmp(2)  := x"41"; -- MOV IMM8, B
			tmp(3)  := x"01"; -- IMM8
			tmp(4)  := x"43"; -- MOV IMM8, D
			tmp(5)  := x"80"; -- IMM8
			tmp(6)  := x"7E"; -- MOV D, C
			tmp(7)  := x"C7"; -- ADD B, D
			tmp(8)  := x"33"; -- ADD IMM8, D
			tmp(9)  := x"05"; -- IMM8
			tmp(10) := x"3E"; -- OR  IMM8, C
			tmp(11) := x"11"; -- IMM8
			tmp(12) := x"DA"; -- XOR C, C
			tmp(13) := x"24"; -- SUB IMM8, A
			tmp(14) := x"03"; -- IMM8
			tmp(15) := x"97"; -- SUB B, D
			tmp(16) := std_logic_vector(to_unsigned(200,8));
		return tmp;
	end init_ram;
	-- MOV IMM8, REG; MOV REG, REG; ADD REG, REG; ADD IMM8, REG; OR IMM8, REG; XOR REG, REG; SUB IMM8, REG; SUB REG, REG
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
