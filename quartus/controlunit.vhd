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
	ModBus2Dst:		out	std_logic;								-- Store whats on ALUBus in register selected by DstSel
	ModSel,
	DstSel:		out	std_logic_vector(1 downto 0);
	MemBus:		in		std_logic_vector(7 downto 0);
	IREG:			out	std_logic_vector(7 downto 0)		--debug
	);
end controlunit;

-- Logic units (whole design): 300 299 298 292 291 290
-- Logic units (control unit): 52 50 53

architecture arch of controlunit is
signal irop:	std_logic_vector(7 downto 0) := x"60";
signal nrop:	std_logic_vector(7 downto 0);
signal cycle:	std_logic_vector(3 downto 0) := "0000";
signal c0, c1, c2:	std_logic;
begin
	IREG <= irop;
	nrop <= not(irop);
	
	process(SYSCLK)
		variable opnum: integer range 0 to 31;
		variable aa: std_logic;
	begin
		if(rising_edge(SYSCLK)) then
			c0 <= '0';
			c1 <= '0';
			c2 <= '0';
			if (cycle = "0000") then
				-- determine which opcodes requires which cycles, all opcodes get a c0 cycle
				opnum := to_integer(unsigned(MemBus(7 downto 3)));
				irop <= MemBus;
				aa := (MemBus(3) xnor MemBus(1)) and (MemBus(2) xnor MemBus(0)); -- if XX is equal to YY (mod == dst)
				case opnum is
					when 1 | 4 =>
						-- IROP + IMM8 cycle // IROP + MEM
						cycle(1) <= '1';
						cycle(2) <= '0';
						cycle(3) <= '0';
					when 0 | 3 =>
						-- IROP + IMM8 + IMM16 cycles // IROP + IMM8 + MEM
						cycle(1) <= '1';
						cycle(2) <= '1';
						cycle(3) <= '0';
					when 2 =>
						-- IROP + IMM8 + IMM16 + MEM cycles
						cycle(1) <= '1';
						cycle(2) <= '1';
						cycle(3) <= '1';
					when 14 to 25 | 28 to 31 =>
						-- All ALU ops, except XOR, and MOV: if MOD == DST, use IMM8 for MOD
						cycle(1) <= aa;
						cycle(2) <= '0';
						cycle(3) <= '0';
					when others =>
						cycle(1) <= '0';
						cycle(2) <= '0';
						cycle(3) <= '0';
				end case;
				c0 <= '1';
			elsif (cycle(1) = '1') then -- IMM8
				c1 <= '1';
				cycle(1) <= '0';
			elsif (cycle(2) = '1') then -- IMM16
				c2 <= '1';
				cycle(2) <= '0';
			elsif (cycle(3) = '1') then -- MEM Access
				-- Nothing actually happens in the mem cycle, setup is in c2
				-- memory cycle is used to set address bus for next instruction
				cycle(3) <= '0';
			end if;
		end if;
	end process;

	process(irop, nrop, c0, c1, c2, F_Carry, F_Zero, F_Sign)
		variable opnum: integer range 0 to 31;
		variable v, jmpflag: std_logic;
	begin
		opnum := to_integer(unsigned(irop(7 downto 3)));

		-- default values
		Mem_OE <= '1';
		Mem_WR <= '0';
		PC_OE <= '1';
		PC_IMMA <= '0';
		PCjump <= '0';
		PCjrel <= '0';
		Mem2IMHi <= '0';
		Mem2IMLo <= '0';
		ALU_OP <= "11"; -- Default ALU_OP=OR causes the least gate-flipping = power saving
		ALU_Cin <= '0';
		F_Store <= '0';
		InvertMod <= '0';
		CD2addr <= '0';
		DstBus2Mem <= '0';
		Mem2ModBus <= '0';
		MemBus2Dst <= '0';
		ALUBus2Dst <= '0';
		ModBus2Dst <= '0';
		ModSel <= "00";
		DstSel <= irop(1 downto 0);
		
		jmpflag := irop(0) xnor (((nrop(2) and irop(1)) and F_Carry) or ((irop(2) and nrop(1)) and F_Zero) or ((irop(2) and irop(1)) and F_Sign));
				
		case opnum is
			when 0 =>
				-- JMP IMM16
				PCjump		<= jmpflag and c1;
				Mem2IMLo		<= c0;
			when 1 =>
				-- JMP REL8
				PCjump		<= jmpflag and c0;
				PCjrel		<= jmpflag and c0;
			when 2 | 3 =>
				-- LD/ST [IMM16], LD/ST [IMM8]
				v := (nrop(3) and c2) or (irop(3) and c1);
				Mem_OE		<= v nand irop(2);
				Mem_WR		<= v and irop(2);
				PC_IMMA		<= v;
				Mem2IMHi		<= c1 and irop(2);
				Mem2IMLo		<= c0;
				DstBus2Mem	<= v and irop(2);
				MemBus2Dst	<= v and nrop(2); -- save membus in dst
			when 4 =>
				-- LD/ST [C:D]
				Mem_OE <= not(c0 and irop(1));
				Mem_WR <= c0 and irop(1);
				PC_OE <= not(c0);
				CD2addr <= c0;
				DstBus2Mem <= c0 and irop(1);
				MemBus2Dst <= c0 and not(irop(1));
				DstSel(1) <= '0';
			when 5 to 13 => null;
			when 14 to 15 =>
				-- MOV 0111xxxx
				v := (irop(3) xnor irop(1)) and (irop(2) xnor irop(0));
				Mem2ModBus	<= c0 and v;
				ModBus2Dst	<= '1';
				ModSel		<= irop(3 downto 2);
			when 16 to 25 | 28 to 31 =>
				-- CMP 1000xxxx, SUB 1001xxxx, SBC 1010xxxx, ADC 1011xxxx
				-- ADD 1100xxxx, AND 1110xxxx, OR 1111xxxx
				v := (irop(3) xnor irop(1)) and (irop(2) xnor irop(0));
				Mem2ModBus	<= c0 and v;
				ALU_OP(0)	<= irop(6) and irop(4);
				ALU_OP(1)	<= irop(6) and irop(5);				
				ALU_Cin		<= nrop(6) and irop(5) and F_Carry;
				F_Store		<= c0;
				InvertMod	<= nrop(6) and (irop(5) nand irop(4));
				ALUBus2Dst	<= c0 and (irop(6) or irop(5) or irop(4));
				ModSel		<= irop(3 downto 2);
			when 26 | 27 =>
				-- XOR 1101xxxx
				ALU_OP		<= irop(5 downto 4);
				F_Store		<= c0;
				ALUBus2Dst	<= c0;
				ModSel		<= irop(3 downto 2);
		end case;
	end process;
end arch;
