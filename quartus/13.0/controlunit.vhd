library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlunit is
port(
	SYSCLK,
	F_Carry,
	F_Zero,
	F_Sign:			in		std_logic;
	Mem_OE,
	Mem_WR,
	PC_OE,
	PChold,
	PCjump,
	PCjrel,
	Mem2IMHi,
	Mem2IMLo:		out	std_logic;
	ALU_OP:			out	std_logic_vector(2 downto 0);
	ALU_Cin,
	F_Store:			out	std_logic;								-- Store ALU flag results in flag bit
	CD2addr,
	DstBus2Mem,															-- ALUBus -> MemBus
	Mem2ModBus,
	MemBus2Dst,
	ALUBus2Dst,
	ModBus2Dst:		out	std_logic;								-- Store whats on ALUBus in register selected by DstSel
	ModSel,
	DstSel:			out	std_logic_vector(1 downto 0);
	MemBus:			in		std_logic_vector(7 downto 0);
	IREG:				out	std_logic_vector(7 downto 0)		--debug
	);
end controlunit;

-- Logic units (whole design/Cyclone II): 300 299 298 292 291 290 265 271 286 285 282 276
-- Logic units (control unit/Cyclone II): 52 50 53 51 58 59 50

architecture arch of controlunit is
signal irop:			std_logic_vector(7 downto 0) := x"F0";
signal nrop:			std_logic_vector(7 downto 0);
signal cycle:			natural range 0 to 3 := 1;
signal mcycle:			std_logic_vector(2 downto 0);
alias  c0:				std_logic is mcycle(0);
alias  c1:				std_logic is mcycle(1);
alias  c2:				std_logic is mcycle(2);
signal r:				std_logic := '1';
signal samereg:		std_logic := '0';
begin
	IREG <= irop;
	nrop <= not(irop);
	
	process(SYSCLK)
		variable opnum: integer range 0 to 31;
		variable nextc: natural range 0 to 3;
	begin
		if(rising_edge(SYSCLK)) then
			r  <= '0';
			mcycle(2 downto 1) <= mcycle(1 downto 0);
			mcycle(0) <= '0';
			nextc := cycle - 1;
			if (cycle = 0) then
				-- determine which opcodes requires which cycles, all opcodes get a c0 cycle
				irop  <= MemBus;
				if (((MemBus(3) xnor MemBus(1)) and (MemBus(2) xnor MemBus(0))) = '1') then
					nextc := 1;
					samereg <= '1';
				else
					nextc := 0;
					samereg <= '0';
				end if;
				opnum := to_integer(unsigned(MemBus(7 downto 3)));
				case opnum is
					when 1 | 4 =>
						-- JMP REL8, LD/ST [C:D]
						-- IROP + IMM8 cycle // IROP + MEM
						nextc := 1;
					when 0 | 3 =>
						-- JMP IMM16, LD/ST IMM16
						-- IROP + IMM8 + IMM16 cycles // IROP + IMM8 + MEM
						nextc := 2;
					when 2 =>
						-- IROP + IMM8 + IMM16 + MEM cycles
						nextc := 3;
					-- when 14 to 29 =>
						-- MOV and all ALU ops, except XOR: if MOD == DST, use IMM8 for MOD
					when 30 | 31 =>
						nextc := 0;
					when others => null;
				end case;
				mcycle <= "001";
			end if;
			cycle <= nextc;
		end if;
	end process;

	process(irop, nrop, c0, c1, c2, F_Carry, F_Zero, F_Sign)
		variable opnum: integer range 0 to 31;
		variable v, jmpflag: std_logic;
	begin
		opnum := to_integer(unsigned(irop(7 downto 3)));

		-- default values
		Mem_OE		<= '1';
		Mem_WR		<= '0';
		PC_OE			<= '1';
		PChold		<= r;
		PCjump		<= '0';
		PCjrel		<= '0';
		Mem2IMHi		<= '0';
		Mem2IMLo		<= '0';
		ALU_OP		<= "010"; -- Default ALU_OP=OR causes the least gate-flipping = power saving
		ALU_Cin		<= '0';
		F_Store		<= '0';
		CD2addr		<= '0';
		DstBus2Mem	<= '0';
		Mem2ModBus	<= '0';
		MemBus2Dst	<= '0';
		ALUBus2Dst	<= '0';
		ModBus2Dst	<= '0';
		ModSel		<= "00";
		DstSel		<= irop(1 downto 0);
		
		case irop(2 downto 1) is
			when "00" => jmpflag := nrop(0);
			when "01" => jmpflag := irop(0) xnor F_Carry;
			when "10" => jmpflag := irop(0) xnor F_Zero;
			when "11" => jmpflag := irop(0) xnor F_Sign;
		end case;

		-- long and complicated, but possibly fewer logic elements
		-- jmpflag := irop(0) xnor (((nrop(2) and irop(1)) and F_Carry) or ((irop(2) and nrop(1)) and F_Zero) or ((irop(2) and irop(1)) and F_Sign));
				
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
				PChold		<= v;
				Mem2IMHi		<= c1 and irop(2);
				Mem2IMLo		<= c0;
				DstBus2Mem	<= v and irop(2);
				MemBus2Dst	<= v and nrop(2);
			when 4 =>
				-- LD/ST [C:D] (only 4 opcodes actually needed)
				Mem_OE		<= not(c0 and irop(1));
				Mem_WR		<= c0 and irop(1);
				PC_OE			<= not(c0);
				CD2addr		<= c0;
				DstBus2Mem	<= c0 and irop(1);
				MemBus2Dst	<= c0 and not(irop(1));
				DstSel(1)	<= '0';
			when 5 to 13 => null;
			when 14 to 15 =>
				-- MOV 0111xxxx
				Mem2ModBus	<= c0 and samereg;
				ModBus2Dst	<= '1';
				ModSel		<= irop(3 downto 2);
			when 16 to 29 =>
				-- CMP 1000xxxx, SUB 1001xxxx, SBC 1010xxxx, ADC 1011xxxx
				-- ADD 1100xxxx, AND 1101xxxx, OR 1110xxxx
				Mem2ModBus	<= c0 and samereg;
				ALU_OP(0)	<= irop(6) and irop(4);
				ALU_OP(1)	<= irop(6) and irop(5);				
				ALU_OP(2)	<= nrop(6) and (irop(5) nand irop(4));
				ALU_Cin		<= nrop(6) and irop(5) and F_Carry;
				F_Store		<= c0;
				ALUBus2Dst	<= c0 and (irop(6) or irop(5) or irop(4));
				ModSel		<= irop(3 downto 2);
			when 30 | 31 =>
				-- XOR 1111xxxx
				ALU_OP		<= "011";
				F_Store		<= '1';
				ALUBus2Dst	<= '1';
				ModSel		<= irop(3 downto 2);
		end case;
	end process;
end arch;
