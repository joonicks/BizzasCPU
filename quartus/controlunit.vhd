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
	F_Store,															-- Store ALU flag results in flag bits
	InvertMod:	out	std_logic;								-- For doing ALU SUB: DST + NOT(Mod) + NOT(Carry) == SUB
	CD2addr,
	DstBus2Mem,														-- ALUBus -> MemBus
	Mem2ModBus,
	MemBus2Dst,
	ALUBus2Dst,
	RegCopy:		out	std_logic;								-- Store whats on ALUBus in register selected by DstSel
	ModSel,
	DstSel:		out	std_logic_vector(1 downto 0);
	MemBus:		in		std_logic_vector(7 downto 0);
	IREG:			out	std_logic_vector(7 downto 0)		--debug
	);
end controlunit;

architecture arch of controlunit is
signal irop:	unsigned(7 downto 0) := x"60";
signal cycle:	unsigned(3 downto 0) := "0000";
signal c0, c1, c2:	std_logic;
begin
	IREG <= std_logic_vector(irop);
	
	process(SYSCLK)
	begin
		if(rising_edge(SYSCLK)) then
			c0 <= '0';
			c1 <= '0';
			c2 <= '0';
			if (cycle = "0000") then
				-- determine which opcodes requires which cycles, all opcodes get a c0 cycle
				if MemBus(7 downto 3) = "01000" then
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
				-- Nothing actually happens in the mem cycle, setup is in c2
				cycle(3) <= '0';
			end if;
		end if;
	end process;

	process(irop, c0, c1, c2, F_Carry, F_Zero, F_Sign)
		variable opnum: integer range 0 to 15;
		variable jmpflag: std_logic;
	begin
		opnum := to_integer(irop(7 downto 4));

		-- default values
		Mem_OE <= '1';
		Mem_WR <= '0';
		PC_OE <= '1';
		PC_IMMA <= '0';
		PCjump <= '0';
		PCjrel <= '0';
		PChold <= '0';
		Mem2IMHi <= '0';
		Mem2IMLo <= '0';
		ALU_OP <= "11"; -- Default ALU_OP=OR causes the least gate-flipping
		ALU_Cin <= '0';
		F_Store <= '0';
		InvertMod <= '0';
		CD2addr <= '0';
		DstBus2Mem <= '0';
		Mem2ModBus <= '0';
		MemBus2Dst <= '0';
		ALUBus2Dst <= '0';
		RegCopy <= '0';
		ModSel <= "00";
		DstSel <= std_logic_vector(irop(1 downto 0));
		case opnum is
			when 0 => -- JMP IMM16, JMP REL8
				case irop(2 downto 1) is
					when "00" => jmpflag := not(irop(0));
					when "01" => jmpflag := F_Carry xnor irop(0); 
					when "10" => jmpflag := F_Zero xnor irop(0);
					when "11" => jmpflag := F_Sign xnor irop(0);
				end case;
				PCjump <= jmpflag and ((c0 and irop(3)) or (c1 and not(irop(3))));
				PCjrel <= jmpflag and c0 and irop(3);
				Mem2IMLo <= c0;
			when 1 => -- MOV [IMM16], MOV [IMM8]
				if (irop(3) = '0') then -- IMM16
					PC_IMMA <= c2;
					Mem2IMHi <= c1;
					if (irop(2) = '1') then -- write
						Mem_OE <= not(c2);
						Mem_WR <= c2;
						DstBus2Mem <= c2;
					end if;
				else
					PC_IMMA <= c1;
					if (irop(2) = '1') then -- write
						Mem_OE <= not(c1);
						Mem_WR <= c1;
						DstBus2Mem <= c1;
					end if;
				end if;
				PChold <= (irop(3) and c1) or (not(irop(3)) and c2);
				Mem2IMLo <= c0;
				MemBus2Dst <= not(irop(2)) and ((irop(3) and c1) or (not(irop(3)) and c2)); -- save membus in dst
			when 2 => -- CMP IMM8, SUB IMM8, SBC IMM8, ADC IMM8
				ALU_OP <= "00";
				ALU_Cin <= (F_Carry and irop(3)) xor (irop(3) nand irop(2));
				F_Store <= c0;
				InvertMod <= irop(3) nand irop(2);
				Mem2ModBus <= c0;
				ALUBus2Dst <= c0 and (irop(4) or irop(3)); -- 0 if 00YY (cmp)
			when 3 => -- ADD IMM8, XOR IMM8, AND IMM8, OR IMM8
				ALU_OP <= std_logic_vector(irop(3 downto 2));
				F_Store <= c0;
				Mem2ModBus <= c0;
				ALUBus2Dst <= c0;
			when 4 => -- MOV IMM, DST
				if (irop(3 downto 2)="00") then
					MemBus2Dst <= c0;
				elsif (irop(3 downto 2) = "01") then
					Mem_OE <= not(c0 and irop(1));
					Mem_WR <= c0 and irop(1);
					PC_OE <= not(c0);
					PChold <= c0;
					CD2addr <= c0;
					DstBus2Mem <= c0 and irop(1);
					MemBus2Dst <= c0 and not(irop(1));
					DstSel(1) <= '0';
				end if;
			when 7 => -- MOV SRC, DST
				RegCopy <= '1';
				ModSel <= std_logic_vector(irop(3 downto 2));
			when 8 to 11 => -- CMP, SUB, SBC, ADC
				ALU_OP <= "00";
				ALU_Cin <= (F_Carry and irop(5)) xor (irop(5) nand irop(4));
				F_Store <= '1';
				InvertMod <= irop(5) nand irop(4);
				ALUBus2Dst <= irop(5) or irop(4);
				ModSel <= std_logic_vector(irop(3 downto 2));
			when 12 to 15 => -- ADD, XOR, AND, OR
				ALU_OP <= std_logic_vector(irop(5 downto 4));
				F_Store <= '1';
				ALUBus2Dst <= '1';
				ModSel <= std_logic_vector(irop(3 downto 2));
			when others => null;
		end case;
	end process;
end arch;
