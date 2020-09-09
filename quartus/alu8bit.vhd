library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8bit_vhdl is
port(
	SYSCLK:		in		std_logic;
	ALU_OP:		in		std_logic_vector(1 downto 0);
	ALU_Cin,
	ALU_Nop,
	F_Store,
	InvertMod:	in		std_logic;
	F_Carry,
	F_Sign,
	F_Zero:		out	std_logic;
	ALUBus:		out	std_logic_vector(7 downto 0);
	ModBus,
	DstBus:		in		std_logic_vector(7 downto 0)
	);
end alu8bit_vhdl;

-- Logic Elements: 46 38 46 49 47

architecture arch of alu8bit_vhdl is
signal adder: std_logic_vector(8 downto 0);
signal extra: unsigned(8 downto 0) := "000000000";
signal Carry, Sign, Zero: std_logic;
begin
	ALUBus <= adder(7 downto 0);

	extra(0) <= ALU_Cin;

	F_Carry <= Carry;
	F_Sign  <= Sign;
	F_Zero  <= Zero;	
	
	process(SYSCLK, F_Store)
	begin
		if (rising_edge(SYSCLK) and F_Store = '1') then
			Carry <= adder(8);
			Sign  <= adder(7);
			Zero  <= not(adder(7) or adder(6) or adder(5) or adder(4) or adder(3) or adder(2) or adder(1) or adder(0));
		end if;
	end process;
	
	process(ALU_OP, ALU_Nop, InvertMod, extra, ModBus, DstBus)
		variable modval: unsigned(7 downto 0);
	begin
		if (ALU_Nop = '1') then
			adder(7 downto 0) <= ModBus;
		else
			if InvertMod = '1' then
				modval := unsigned(not(ModBus));
			else
				modval := unsigned(ModBus);
			end if;
			case (ALU_OP) is
				when "00"  => adder <= std_logic_vector(unsigned('0' & DstBus) + unsigned(InvertMod & modval) + extra);
				when "01"  => adder(7 downto 0) <= ModBus xor DstBus;
				when "10"  => adder(7 downto 0) <= ModBus and DstBus;
				when "11"  => adder(7 downto 0) <= ModBus or  DstBus;
			end case;
		end if;
	end process;
end arch;
