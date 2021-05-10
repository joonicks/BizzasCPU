library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8bit is
port(
	SYSCLK:		in		std_logic;
	ALU_OP:		in		std_logic_vector(2 downto 0);
	ALU_Cin,
	F_Store:		in		std_logic;
	F_Carry,
	F_Zero,
	F_Sign:		out	std_logic;
	ALUBus:		out	unsigned(7 downto 0);
	ModBus,
	DstBus:		in		unsigned(7 downto 0)
	);
end alu8bit;

-- Logic Elements: 46 38 46 49 47 38 42

architecture arch of alu8bit is
signal accum:  unsigned(8 downto 0);
begin
	ALUBus <= accum(7 downto 0);

	process(SYSCLK, F_Store)
	begin
		if (rising_edge(SYSCLK) and F_Store = '1') then
			F_Carry <= accum(8);
			F_Zero  <= not(accum(7) or accum(6) or accum(5) or accum(4) or accum(3) or accum(2) or accum(1) or accum(0));
			F_Sign  <= accum(7);
		end if;
	end process;
	
	process(ALU_OP, ALU_Cin, ModBus, DstBus)
		variable modval: unsigned(8 downto 0) := "000000000";
	begin
		case(ALU_OP) is
			-- 001 AND
			when "001" => accum <= '0' & (ModBus and DstBus);
			-- 010 OR
			when "010" => accum <= '0' & (ModBus or  DstBus);
			-- 011 XOR
			when "011" => accum <= '0' & (ModBus xor DstBus);
			when others =>
			-- 000 ADD
			-- 100 SUB
				modval(0) := ModBus(0) xor ALU_OP(2);
				modval(1) := ModBus(1) xor ALU_OP(2);
				modval(2) := ModBus(2) xor ALU_OP(2);
				modval(3) := ModBus(3) xor ALU_OP(2);
				modval(4) := ModBus(4) xor ALU_OP(2);
				modval(5) := ModBus(5) xor ALU_OP(2);
				modval(6) := ModBus(6) xor ALU_OP(2);
				modval(7) := ModBus(7) xor ALU_OP(2);
				modval(8) := ALU_OP(2);
				if (ALU_Cin /= ALU_OP(2)) then
					modval := modval + 1;
				end if;
				accum <= ('0' & DstBus) + modval;
		end case;
	end process;
end arch;
