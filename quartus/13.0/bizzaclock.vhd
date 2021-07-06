library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bizzaclock is
port(
	RefClk:		in		std_logic;
	SYSCLK:		out	std_logic
	);
end bizzaclock;


architecture arch of bizzaclock is
signal counter: natural range 0 to 1048575;
signal c: std_logic;
begin
	process(RefClk)
	begin
		if (rising_edge(RefClk)) then
			counter <= counter + 1;
			if (counter >= 10000) then
				counter <= 0;
				c <= not(c);
			end if;
			SYSCLK <= c;
		end if;
	end process;
end arch;
