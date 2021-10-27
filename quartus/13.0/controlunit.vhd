library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlunit is
port(
	SYSCLK,
	F_Carry,
	F_Zero,
	F_Sign:			in		std_logic;
	Mem_OE:			out	std_logic;
	Mem_WR:			out	std_logic;
	PChold,
	PCjrel:			out	std_logic;
	AdrSel:			out	std_logic_vector(1 downto 0);
	ModSel,
	DstSel:			out	std_logic_vector(2 downto 0);
	Bus2Dst:			out	std_logic_vector(1 downto 0);
	Dst2Mem:			out	std_logic;
	MemBus:			in		std_logic_vector(7 downto 0);
	ALU_OP:			out	std_logic_vector(2 downto 0);
	ALU_Cin,
	F_Store:			out	std_logic;								-- Store ALU flag results in flag bit
	IREG:				out	std_logic_vector(7 downto 0)		-- debug
	);
end controlunit;

-- Logic units (whole design/Cyclone II): 300 299 298 292 291 290 265 271 286 285 282 276 267 265 263 258 300 305 301 311 290 296
-- Logic units (control unit/Cyclone II): 52 50 53 51 58 59 50 52 51 49 58 67 74 70

architecture arch of controlunit is
signal IR:			std_logic_vector(7 downto 0);
signal cycle:		natural range 0 to 3 := 1;
signal mcycle:		std_logic_vector(3 downto 0);
alias  c0:			std_logic is mcycle(0);
alias  c1:			std_logic is mcycle(1);
alias  c2:			std_logic is mcycle(2);
alias  c3:			std_logic is mcycle(3);
signal r:			std_logic := '1';
signal samereg:	std_logic;
alias  IR0:			std_logic is IR(0);
alias  IR1:			std_logic is IR(1);
alias  IR2:			std_logic is IR(2);
alias  IR3:			std_logic is IR(3);
alias  IR4:			std_logic is IR(4);
alias  IR5:			std_logic is IR(5);
alias  IR6:			std_logic is IR(6);
alias  IR7:			std_logic is IR(7);
begin
	-- debug output
	IREG <= IR;
	
	process(SYSCLK)
		variable opnum: natural range 0 to 255;
		variable nextc: natural range 0 to 3;
	begin
		if(rising_edge(SYSCLK)) then
			r  <= '0';
			mcycle(3 downto 1) <= mcycle(2 downto 0);
			mcycle(0) <= '0';
			nextc := cycle - 1;
			if (cycle = 0) then
				-- determine which opcodes requires which cycles, all opcodes get a c0 cycle
				IR  <= MemBus;
				if (((MemBus(3) xnor MemBus(1)) and (MemBus(2) xnor MemBus(0))) = '1') then
					nextc := 1;
					samereg <= '1';
				else
					nextc := 0;
					samereg <= '0';
				end if;
				opnum := to_integer(unsigned(MemBus));
				case opnum is
				when 16 to 23				=> nextc := 3; -- LD/ST imm16
				when 0 to 7 | 24 to 31	=> nextc := 2; -- JMP imm16, LD/ST [E:imm8]
				when 8 to 15 | 32 to 47	=> nextc := 1; -- JMP rel8, LD/ST [E:reg]
				when 48 to 127				=> nextc := 0; -- SHR, SHL, RCR, RCL, INC, DEC, XOR and unallocated opcodes
				when others					=> null;			-- ALU ops (1 if samereg, else 0)
				end case;
				mcycle <= "0001";
			end if;
			cycle <= nextc;
		end if;
	end process;
	
	process(SYSCLK, IR, c0, c1, c2, F_Carry, F_Zero, F_Sign, r, samereg)
		variable opnum: natural range 0 to 255;
		variable jmpflag: std_logic;
	begin
		-- default values
		Mem_OE		<= '1';
		Mem_WR		<= '0';
		PChold		<= r;
		PCjrel		<= '0';
		AdrSel		<= "00";
		ModSel		<= (samereg and IR7) & (not(samereg) and IR3) & (not(samereg) and IR2);
		DstSel		<= '0' & IR(1 downto 0);
		Bus2Dst		<= "00";
		Dst2Mem		<= '0';
		ALU_OP		<= "010"; -- Default ALU_OP=OR causes the least gate-flipping = power saving
		ALU_Cin		<= '0';
		F_Store		<= '0';
		
		case IR(2 downto 1) is
			when "00" => jmpflag := not(IR0);
			when "01" => jmpflag := IR0 xnor F_Carry;
			when "10" => jmpflag := IR0 xnor F_Zero;
			when "11" => jmpflag := IR0 xnor F_Sign;
		end case;
		
		opnum := to_integer(unsigned(IR));
		case opnum is
			when 0 to 7 =>
				-- 00000xxx JMP imm16									copy imm16 to MR, if (jmpflag) PC = MR, MR = old PC
				AdrSel(0)	<= jmpflag and c2;
				DstSel		<= not(c2) & '0' & c1;					-- c0 -- DstSel "100": MR = zero & data
																				-- c1 -- DstSel "101": MRHi = data
				-- Bus2Dst "10": data = MemBus
				Bus2Dst(1)	<= not(SYSCLK) and (c0 or (c1 and IR0 and (IR2 nor IR1)));
			when 8 to 15 =>
				-- 00001xxx JMP rel8										copy zero & rel8 to MR, if (jmpflag) PC = PC + MR
				PCjrel		<= jmpflag and c0;
				DstSel		<= c0 & "00";								-- c0: DstSel "100": MR := zero & data
				Bus2Dst(1)	<= not(SYSCLK) and (c0 and IR0 and (IR2 nor IR1));
			when 16 to 19 =>
				-- $10 ... $13
				-- 000100YY LD  [imm16], dst							copy imm16 to MR, put MR on address bus, copy MemBus to DstSel
				PChold		<= c2;
				AdrSel(0)	<= c2;										-- c2: "01" Address bus = MRHi:MRLo
				if ((c0 or c1) = '1') then
					DstSel	<= "10" & c1;								-- c0: DstSel "100" MR := zero & data;
																				-- c1: DstSel "101" MRHi := data;
				end if;
				Bus2Dst(1)	<= not(c3);									-- "10" data := MemBus
			when 20 to 23 =>
				-- 000101YY ST  src, [imm16]							copy imm16 to MR, put MR on address bus, put DstSel on MemBus, Mem_WR
				-- $14 #20  ST  A, [imm16]
				-- $15 #21  ST  B, [imm16]
				-- $16 #22  ST  C, [imm16]
				-- $17 #23  ST  D, [imm16]
				Mem_OE		<= not(c2);
				Mem_WR		<= c2;
				PChold		<= c2;
				AdrSel(0)	<= c2;										-- c2: "01" Address bus = MRHi:MRLo
				if ((c0 or c1) = '1') then
					DstSel	<= "10" & c1;								-- c0: DstSel "100" MR := zero & data;
																				-- c1: DstSel "101" MRHi := data;
				end if;
				Bus2Dst(1)	<= c0 or c1;								-- "10" data := MemBus
				Dst2Mem		<= c2;
			when 24 to 27 =>
				-- 000110YY LD  [E:imm8], dst
				PChold		<= c1;										-- Dont increment PC during memory access
				AdrSel(0)	<= c1;										-- c1: "01" Address bus = MRHi:MRLo
				DstSel		<= c0 & (c0 or IR1) & (c0 or IR0);	-- c0: DstSel "111" MR := regE & data
				Bus2Dst(1)	<= c0 or c1;								-- "10" data := MemBus
			when 28 to 31 =>
				-- 000111YY ST  src, [E:imm8]							-- <c0> copy regE:MemBus to MR <c1> put MR on address bus, put DstSel on MemBus, Mem_WR
				Mem_OE		<= not(c2);
				Mem_WR		<= c1;
				PChold		<= c1;										-- Dont increment PC during memory access
				AdrSel(0)	<= c1;
				DstSel		<= c0 & (c0 or IR1) & (c0 or IR0);	-- c0: DstSel "111" MR := regE & data
				Bus2Dst(1)	<= c0;										-- "10" data := MemBus
				Dst2Mem		<= '1';
			when 32 to 39 =>
				-- 00100RXX LD [E:reg], dst							-- <c0> put regE:ModBus on address bus, copy MemBus to DstSel
				PChold		<= c0;
				AdrSel(1)	<= c0;										-- c0: "10" Address bus = regE:ModBus
				ModSel		<= "01" & IR2;								-- put C or D on ModBus
				Bus2Dst(1)	<= c0;										-- c0: "10" data := MemBus
			when 40 to 47 =>
				-- 00101RYY ST src, [E:reg]							put regE:ModBus on address bus, put DstSel on MemBus, Mem_WR
				Mem_OE		<= not(c2);
				Mem_WR		<= c0;
				PChold		<= c0;
				AdrSel(1)	<= c0;										-- c0: "10" Address bus = regE:ModBus
				ModSel		<= "01" & IR2;								-- put C or D on ModBus
				Bus2Dst(1)	<= c0;										-- c0: "10" data := MemBus
				Dst2Mem		<= '1';
			when 48 =>
				-- 00110000 MOV MR, C:D									copy MRHi to C, copy MRLo to D
				Bus2Dst		<= "01";
				DstSel		<= "111";
			when 49 | 50 =>
				-- 00110001 JMP C:D										-- AdrSel = "11"
				-- 00110010 JMP MR										-- AdrSel = "01"
				AdrSel		<= IR0 & '1';
			when 51 to 79 => null;
			when 80 to 95 =>
				-- 010100YY SHR reg
				-- 010101YY SHL reg
				-- 010110YY RCR reg
				-- 010111YY RCL reg
				ALU_OP		<= "11" & IR(2);
				ALU_Cin		<= IR(3) and F_Carry;
				F_Store		<= '1';										-- save flags
				Bus2Dst		<= "01";										-- "01" data := ALUBus
			when 96 | 97 =>
				-- 0110000X MOV E, dst
				DstSel		<= "01" & IR0;								-- DstSel = C or D
				ModSel		<= "110";									-- regE := data
				Bus2Dst		<= "11";										-- "11" data := ModBus
			when 98 | 99 =>
				-- 0110001Y MOV src, E
				ModSel		<= "01" & IR0;								-- ModBus = C or D
				DstSel		<= "110";									-- regE := data
				Bus2Dst		<= "11";										-- "11" data := ModBus
			when 100 to 103 => null;
			when 104 to 111 =>
				-- 011010YY INC reg
				-- 011011YY DEC reg
				ALU_OP		<= IR(2) & "00";
				F_Store		<= '1';
				ModSel		<= "111";									-- "111" constant value one
				Bus2Dst		<= "01";										-- "01" data := ALUBus
			when 112 to 127 =>
				-- 0111XXYY XOR src, dst
				ALU_OP		<= "011";									-- "011" XOR
				F_Store		<= '1';
				Bus2Dst		<= "01";										-- "01" data := ALUBus
			when 192 to 207 =>
				-- 1100XXYY CMP src, dst
				ALU_OP		<= "100";									-- "100" SUB
				ALU_Cin		<= F_Carry;
				F_Store		<= '1';
			when 128 to 191 | 208 to 239 =>
				--   operand		ALU	Cin	Bus2Dst
				-- 1000xxxx ADD 	000	0		01
				-- 1001xxxx AND 	001	n/a	01
				-- 1010xxxx OR  	010	n/a	01
				-- 1011xxxx ADC 	000	1		01
				-- 1101xxxx SUB 	100	0		01
				-- 1110xxxx SBC 	100	1		01
				ALU_OP(2)	<= IR(6);
				ALU_OP(1)	<= IR(5) and (IR(5) xnor IR(4)) and not(IR(6));
				ALU_OP(0)	<= IR(4) and (IR(5) xnor IR(4)) and not(IR(6));
				ALU_Cin		<= IR(5) and F_Carry;
				F_Store		<= '1';
				Bus2Dst(0)	<= c0;
			when 240 to 255 =>
				-- 1111xxxx MOV src, dst								(samereg = 0) copy ModSel to DstSel
				-- 1111xxxx MOV imm8, dst								(samereg = 1) copy MemBus to DstSel
				Bus2Dst		<= c0 & c0;									-- "11" data := ModBus
		end case;
	end process;
end arch;
