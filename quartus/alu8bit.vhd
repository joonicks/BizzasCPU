library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8bit is
port(
	SYSCLK:		in		std_logic;
	ALU_OP:		in		std_logic_vector(1 downto 0);
	ALU_Cin,
	F_Store,
	InvertMod:	in		std_logic;
	F_Carry,
	F_Zero,
	F_Sign:		out	std_logic;
	ALUBus:		out	std_logic_vector(7 downto 0);
	ModBus,
	DstBus:		in		std_logic_vector(7 downto 0)
	);
end alu8bit;

-- Logic Elements: 46 38 46 49 47

architecture arch of alu8bit is
signal adder: std_logic_vector(8 downto 0);
signal extra: unsigned(8 downto 0) := "000000000";
signal Carry, Sign, Zero: std_logic;
begin
	ALUBus <= adder(7 downto 0);

	extra(0) <= ALU_Cin xor InvertMod;

	F_Carry <= Carry;
	F_Zero  <= Zero;	
	F_Sign  <= Sign;
	
	process(SYSCLK, F_Store)
	begin
		if (rising_edge(SYSCLK) and F_Store = '1') then
			Carry <= adder(8);
			Zero  <= not(adder(7) or adder(6) or adder(5) or adder(4) or adder(3) or adder(2) or adder(1) or adder(0));
			Sign  <= adder(7);
		end if;
	end process;
	
	process(ALU_OP, InvertMod, extra, ModBus, DstBus)
		variable modval: unsigned(7 downto 0);
	begin
		if InvertMod = '1' then
			modval := unsigned(not(ModBus));
		else
			modval := unsigned(ModBus);
		end if;
		case (ALU_OP) is
			when "00"  => adder <= std_logic_vector(unsigned('0' & DstBus) + unsigned(InvertMod & modval) + extra);
			when "01"  => adder <= '0' & (ModBus xor DstBus);
			when "10"  => adder <= '0' & (ModBus and DstBus);
			when "11"  => adder <= '0' & (ModBus or  DstBus);
		end case;
	end process;
end arch;
