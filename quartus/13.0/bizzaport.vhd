library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bizzaport is
port(
	SYSCLK:		in		std_logic;
	Mem_WR,
	Mem_OE:		in		std_logic;
	OutPort:		out	unsigned(7 downto 0);
	MemBus,
	addrLo,
	addrHi:		in		unsigned(7 downto 0)
	);
end bizzaport;


architecture arch of bizzaport is
signal port8: unsigned(7 downto 0) := x"00";
begin
	OutPort <= port8;
	
	process(SYSCLK, addrLo, addrHi, Mem_WR)
	begin
		if (rising_edge(SYSCLK) and addrHi = "11010000" and addrLo = "01110111" and Mem_WR = '1') then
			port8 <= MemBus;
		end if;
	end process;
end arch;
