library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity progcounter is
port(
	SYSCLK,
	PC_OE,
	PC_IMMA,
	PCjump,
	PCjrel,
	PChold,
	Mem2IMHi,
	Mem2IMLo:	in		std_logic;
	addrLo:		out	std_logic_vector(7 downto 0);
	addrHi:		out	std_logic_vector(7 downto 0);
	MemBus:		in		std_logic_vector(7 downto 0)
	);
end progcounter;

-- Logic Units: 47 53

architecture arch of progcounter is
signal inpc:	unsigned(15 downto 0) := x"0000";
signal imma:	unsigned(15 downto 0) := x"0000";
alias  inpcHi:	unsigned( 7 downto 0) is inpc(15 downto 8);
alias  inpcLo:	unsigned( 7 downto 0) is inpc( 7 downto 0);
alias  immaHi:	unsigned( 7 downto 0) is imma(15 downto 8);
alias  immaLo:	unsigned( 7 downto 0) is imma( 7 downto 0);
begin
	addrLo <= std_logic_vector(inpcLo) when PC_OE = '1' else
				 std_logic_vector(immaLo) when PC_IMMA = '1' else "ZZZZZZZZ";
	addrHi <= std_logic_vector(inpcHi) when PC_OE = '1' else
				 std_logic_vector(immaHi) when PC_IMMA = '1' else "ZZZZZZZZ";
	
	process(SYSCLK, PChold)
	begin
		if (rising_edge(SYSCLK) and PChold = '0') then
			if (Mem2IMLo = '1') then
				immaLo <= unsigned(MemBus);
				immaHi <= "00000000";
			end if;
			if (Mem2IMHi = '1') then
				immaHi <= unsigned(MemBus);
			end if;
			if (PCjump = '1') then
				if (PCjrel = '0') then
					inpcHi <= unsigned(MemBus);
					inpcLo <= immaLo;
				else
					inpc <= inpc + unsigned(resize(signed(MemBus),16));
				end if;
			else
				inpc <= inpc + 1;
			end if;
		end if;
	end process;
end arch;
