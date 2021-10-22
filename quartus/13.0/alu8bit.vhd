library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu8bit is
port(
	SYSCLK:		in		std_logic;
	ALU_OP:		in		std_logic_vector(2 downto 0);
	ALU_Cin,
	F_Store:		in		std_logic;
	F_Carry,
	F_Zero,
	F_Sign:		out	std_logic;
	ALUBus:		out	std_logic_vector(7 downto 0);
	ModBus,
	DstBus:		in		std_logic_vector(7 downto 0)
	);
end alu8bit;

-- Logic Elements: 46 38 46 49 47 38 42 67

architecture arch of alu8bit is
signal accum: std_logic_vector(8 downto 0);
begin
	ALUBus <= accum(7 downto 0);

	process(SYSCLK, F_Store) begin
		if (rising_edge(SYSCLK) and F_Store = '1') then
			F_Carry <= accum(8);
			F_Zero  <= not(accum(7) or accum(6) or accum(5) or accum(4) or accum(3) or accum(2) or accum(1) or accum(0));
			F_Sign  <= accum(7);
		end if;
	end process;

	process(ALU_OP, ALU_Cin, ModBus, DstBus)
		variable modval: std_logic_vector(8 downto 0);
	begin
		case(ALU_OP) is
			when "001" =>
				-- 001 AND
				accum <= '0' & (ModBus and DstBus);
			when "010" =>
				-- 010 OR
				accum <= '0' & (ModBus or  DstBus);
			when "011" =>
				-- 011 XOR
				accum <= '0' & (ModBus xor DstBus);
			when "000" | "100" | "101" =>
				-- 000 ADD
				-- 100 SUB
				if (ALU_OP(2) = '1') then
					modval := '1' & not(ModBus);
				else
					modval := '0' & ModBus;
				end if;
				if ((ALU_OP(2) xor ALU_Cin) = '1') then
					modval := modval + 1;
				end if;
				accum <= ('0' & DstBus) + modval;
			when "110" =>
				-- 110 SHR Shift Right; divide by 2
				accum <= DstBus(0) & ALU_Cin & DstBus(7 downto 1);
			when "111" =>
				-- 111 SHL Shift Left; multiply by 2
				accum <= DstBus & ALU_Cin;
		end case;
	end process;
end arch;
