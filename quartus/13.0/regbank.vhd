library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity regbank is
port(
	SYSCLK,
	PChold,
	PCjump,
	PCjrel,
	Reg2addr,
	DstBus2Mem:		in			std_logic;
	ModSel,
	DstSel:			in			std_logic_vector(2 downto 0);
	Bus2Dst:			in			std_logic_vector(1 downto 0);
	ALUBus:			in			std_logic_vector(7 downto 0);
	MemBus,
	ModBus:			inout		std_logic_vector(7 downto 0);
	DstBus:			buffer	std_logic_vector(7 downto 0);
	addrHi,
	addrLo,
	A, B,	C,	D:		out		std_logic_vector(7 downto 0);
	IM:				out		std_logic_vector(15 downto 0)
	);
end regbank;

-- Logic Elements: 36 37 44 36(68) 100 97 94 84 107 203 194 167

architecture arch of regbank is
signal inpc:	std_logic_vector(15 downto 0) := x"0000";
alias  inpcHi:	std_logic_vector( 7 downto 0) is inpc(15 downto 8);
alias  inpcLo:	std_logic_vector( 7 downto 0) is inpc( 7 downto 0);
signal imma:	std_logic_vector(15 downto 0) := x"0000";
alias  immaHi:	std_logic_vector( 7 downto 0) is imma(15 downto 8);
alias  immaLo:	std_logic_vector( 7 downto 0) is imma( 7 downto 0);
signal regA, regB, regC, regD: std_logic_vector(7 downto 0);
alias  M7:		std_logic is MemBus(7);
begin	
	MemBus <= DstBus when DstBus2Mem = '1'	else "ZZZZZZZZ";

	addrLo <= ModBus when Reg2addr = '1'	else
				 immaLo when PChold = '1'		else inpcLo;
	addrHi <= immaHi when Reg2addr = '1'	else 
				 immaHi when PChold = '1'		else inpcHi;
	
	process(SYSCLK, PCjump, PCjrel, PChold, Reg2addr, Membus, immaLo)
		variable inmod: std_logic_vector(15 downto 0);
	begin
		if (rising_edge(SYSCLK)) then
			if (PCjump = '1') then
				inmod := MemBus & immaLo;
			elsif (PCjrel = '1') then
				inmod := inpc + (M7 & M7 & M7 & M7 & M7 & M7 & M7 & M7 & MemBus);
			else
				inmod := inpc + not(PChold or Reg2addr);
			end if;
			inpc <= inmod;
		end if;
	end process;

	-- debug outputs
	A <= regA;
	B <= regB;
	C <= regC;
	D <= regD;
	IM <= imma;
	
	-- DstBus output is never actually used unless it is a register
	DstBus <=	regA		when DstSel = "000" else
					regB		when DstSel = "001" else
					regC		when DstSel = "010" else
					regD;
	
	ModBus <=	regA		when ModSel = "000" else
					regB		when ModSel = "001" else
					regC		when ModSel = "010" else
					regD		when ModSel = "011" else
					immaLo	when ModSel = "100" else
					immaHi	when ModSel = "101" else
					x"01"		when ModSel = "110" else
					MemBus; --	  ModSel = "111"

	process(SYSCLK, Bus2Dst, DstSel, ModSel)
		variable data: std_logic_vector(7 downto 0);
	begin
		if (rising_edge(SYSCLK) and Bus2Dst /= "00") then
			case Bus2Dst is
			when "00" => data := ModBus; -- Cant happen
			when "01" => data := ALUBus;
			when "10" => data := MemBus;
			when "11" => data := ModBus;
			end case;
			
			case DstSel is
			when "000" => regA <= data;
			when "001" => regB <= data;
			when "010" => regC <= data;
			when "011" => regD <= data;
			when "100" => imma <= "00000000" & data;
			when "101" => immaHi <= data;
			when "110" => immaLo <= data; -- Unused;
			when "111" => immaLo <= data; -- Unused;
			end case;
		end if;
	end process;	
end arch;
