library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlunit is
port(
	SYSCLK,
	F_Carry,
	F_Zero,
	F_Sign:		in		std_logic;
	Mem_OE,
	Mem_WR,
	PC_OE,
	PC_IMMA,
	PCjump,
	PCjrel,
	PChold,
	Mem2IMHi,
	Mem2IMLo:	out	std_logic;
	ALU_OP:		out	std_logic_vector(1 downto 0);
	ALU_Cin,
	ALU_Nop,															-- ModBus -> ALUBus unmodified
	F_Store,															-- Store ALU flag results in flag bits
	InvertMod:	out	std_logic;								-- For doing ALU SUB: DST + NOT(Mod) + NOT(Carry) == SUB
	IREG:			out	std_logic_vector(7 downto 0);--debug
	ALUBus2Mem,														-- ALUBus -> MemBus
	Mod2ModBus,
	ALUBus2Dst:	out	std_logic;								-- Store whats on ALUBus in register selected by DstSel
	ModSel,
	DstSel:		out	std_logic_vector(1 downto 0);
	MemBus:		in		std_logic_vector(7 downto 0)
	);
end controlunit;

-- For: MOV MOD, [IMM16]; MOV MOD, [IMM8]
-- Assert ALU_Nop
-- Assert ALUBus2Mem

architecture arch of controlunit is
signal irop:	unsigned(7 downto 0) := x"60";
signal cycle:	unsigned(3 downto 0);
signal c0, c1, c2, c3:	std_logic;
begin
	IREG <= std_logic_vector(irop);
	
	process(SYSCLK)
	begin
		if(rising_edge(SYSCLK)) then
			c0 <= '0';
			c1 <= '0';
			c2 <= '0';
			c3 <= '0';
			if (cycle = "0000") then
				-- determine which opcodes requires which cycles, all opcodes get a c0 cycle
				if MemBus(7 downto 2) = "010000" then
					cycle(1) <= '1';
				else
					cycle(1) <= not(MemBus(7) or MemBus(6));
				end if;
				cycle(2) <= not(MemBus(7) or MemBus(6) or MemBus(5) or MemBus(3));
				cycle(3) <= not(MemBus(7) or MemBus(6) or MemBus(5) or not(MemBus(4)));
				irop <= unsigned(MemBus);
				c0 <= '1';
			elsif (cycle(1) = '1') then -- IMM8, IMM16_LO
				c1 <= '1';
				cycle(1) <= '0';
			elsif (cycle(2) = '1') then -- IMM16_HI
				c2 <= '1';
				cycle(2) <= '0';
			elsif (cycle(3) = '1') then -- MEM Access
				c3 <= '1';
				cycle(3) <= '0';
			end if;
		end if;
	end process;
	
	-- Dont let Memory drive MemBus in memory
	-- todo: unless reading
	Mem_OE <= irop(2) when cycle = "0001" else '1';
	PC_OE <= '1';
	DstSel <= std_logic_vector(irop(1 downto 0));
	
	process(irop, c0)
		variable opnum: integer range 0 to 15;
	begin
		opnum := to_integer(irop(7 downto 4));
		case opnum is
			when 2 => -- CMP IMM8, SUB IMM8, SBC IMM8, ADC IMM8
				ALU_Cin <= '1'; --(F_Carry and irop(3)) xor (irop(3) nand irop(2)));
				ALU_Nop <= '0';
				F_Store <= '1';
				Mod2ModBus <= '0';
				ALUBus2Dst <= c0 and (irop(4) nor irop(3)); -- 1 if 00YY
				InvertMod <= irop(3) nand irop(2);
				ALU_OP <= "00";
			when 3 => -- ADD, XOR, AND, OR
				ALU_Nop <= '0';
				F_Store <= '1';
				InvertMod <= '0';
				Mod2ModBus <= '0';
				ALUBus2Dst <= c0;
				ALU_OP <= std_logic_vector(irop(3 downto 2));
			when 4 => -- MOV IMM, DST
				ALU_Nop <= '1';
				F_Store <= '0';
				Mod2ModBus <= '0';
				ALUBus2Dst <= c0;
			when 7 => -- MOV SRC, DST
				ALU_Nop <= '1';
				F_Store <= '1';
				InvertMod <= '0';
				Mod2ModBus <= '1';
				ALUBus2Dst <= '1';
				ModSel <= std_logic_vector(irop(3 downto 2));
			when 8 to 11 => -- CMP, SUB, SBC, ADC
				ALU_Cin <= (F_Carry and irop(5)) xor (irop(5) nand irop(4));
				ALU_Nop <= '0';
				F_Store <= '1';
				InvertMod <= irop(5) nand irop(4);
				Mod2ModBus <= '1';
				ALUBus2Dst <= irop(5) or irop(4);
				ALU_OP <= "00";
				ModSel <= std_logic_vector(irop(3 downto 2));
			when 12 to 15 => -- ADD, XOR, AND, OR
				ALU_Cin <= '0';
				ALU_Nop <= '0';
				F_Store <= '1';
				InvertMod <= '0';
				Mod2ModBus <= '1';
				ALUBus2Dst <= '1';
				ALU_OP <= std_logic_vector(irop(5 downto 4));
				ModSel <= std_logic_vector(irop(3 downto 2));
			when others =>
				ALU_Cin <= '0';
				ALU_Nop <= '0';
				F_Store <= '0';
				InvertMod <= '0';
				Mod2ModBus <= '0';
				ALUBus2Dst <= '0';
				ALU_OP <= "00";
				ModSel <= "00";
		end case;
	end process;
end arch;
