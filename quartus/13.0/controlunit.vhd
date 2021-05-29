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
	Mem_WR:			buffer std_logic;
	PChold,
	PCjump,
	PCjrel:			out	std_logic;
	Reg2addr,
	DstBus2Mem:		out	std_logic;
	ModSel,
	DstSel:			out	std_logic_vector(2 downto 0);
	Bus2Dst:			out	std_logic_vector(1 downto 0);
	MemBus:			in		std_logic_vector(7 downto 0);
	ALU_OP:			out	std_logic_vector(2 downto 0);
	ALU_Cin,
	F_Store:			out	std_logic;								-- Store ALU flag results in flag bit
	IREG:				out	std_logic_vector(7 downto 0)		-- debug
	);
end controlunit;

-- Logic units (whole design/Cyclone II): 300 299 298 292 291 290 265 271 286 285 282 276 267 265 263 258 300 305 301 311 290
-- Logic units (control unit/Cyclone II): 52 50 53 51 58 59 50 52 51 49 58 67 74 70

architecture arch of controlunit is
signal irop:			std_logic_vector(7 downto 0);
signal nrop:			std_logic_vector(7 downto 0);
signal cycle:			natural range 0 to 3 := 1;
signal mcycle:			std_logic_vector(3 downto 0);
alias  c0:				std_logic is mcycle(0);
alias  c1:				std_logic is mcycle(1);
alias  c2:				std_logic is mcycle(2);
alias  c3:				std_logic is mcycle(3);
signal r:				std_logic := '1';
signal samereg:		std_logic := '0';
begin
	IREG <= irop;
	
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
				irop  <= MemBus;
				nrop	<= not(MemBus);
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
				when 0 to 7 | 24 to 63	=> nextc := 2; -- JMP imm16, LD/ST imm8 zeropage
				when 8 to 15				=> nextc := 1; -- JMP rel8, LD/ST [imm8:reg]
				when 64 to 127				=> nextc := 0; -- SHR, SHL, RCR, RCL, INC, DEC, XOR and unallocated opcodes
				when others					=> null;			-- ALU ops (1 if samereg, else 0)
				end case;
				mcycle <= "0001";
			end if;
			cycle <= nextc;
		end if;
	end process;

	process(Mem_WR)
	begin
		Mem_OE <= not(Mem_WR);
	end process;
	
	process(SYSCLK, irop, nrop, c0, c1, c2, F_Carry, F_Zero, F_Sign, r, samereg)
		variable opnum: natural range 0 to 255;
		variable jmpflag: std_logic;
	begin
		-- default values
		Mem_WR		<= '0';
		PChold		<= r;
		PCjump		<= '0';
		PCjrel		<= '0';
		Reg2addr		<= '0';
		DstBus2Mem	<= '0';
		ModSel(2)	<= irop(7) and samereg;
		ModSel(1)	<= irop(3);
		ModSel(0)	<= irop(2);
		DstSel		<= '0' & irop(1 downto 0);
		Bus2Dst		<= "00";
		ALU_OP		<= "010"; -- Default ALU_OP=OR causes the least gate-flipping = power saving
		ALU_Cin		<= '0';
		F_Store		<= '0';
		
		case irop(2 downto 1) is
			when "00" => jmpflag := nrop(0);
			when "01" => jmpflag := irop(0) xnor F_Carry;
			when "10" => jmpflag := irop(0) xnor F_Zero;
			when "11" => jmpflag := irop(0) xnor F_Sign;
		end case;

		-- long and complicated, but possibly fewer logic elements
--		jmpflag := irop(0) xnor (((nrop(2) and irop(1)) and F_Carry) or ((irop(2) and nrop(1)) and F_Zero) or ((irop(2) and irop(1)) and F_Sign));
		
		opnum := to_integer(unsigned(irop));
		case opnum is
			when 0 to 7 =>
				-- 00000xxx JMP imm16
				PCjump		<= jmpflag and c1;
				 -- c0 -- DstSel "100": immaLo = data
				 -- c1 -- DstSel "101": immaHi = data
				DstSel(2)	<= c0 or c1;
				DstSel(1)	<= '0';
				DstSel(0)	<= c1;
				-- Bus2Dst "10": data = MemBus
				Bus2Dst(1)	<= not(SYSCLK) and (c0 or (c1 and irop(0) and (irop(2) nor irop(1))));
				Bus2Dst(0)	<= '0';
			when 8 to 15 =>
				-- 00001xxx JMP rel8
				PCjrel		<= jmpflag and c0;
				 -- c0 -- DstSel "100": immaLo = data
				DstSel(2)	<= c0;
				DstSel(1)	<= '0';
				DstSel(0)	<= '0';
				Bus2Dst(1)	<= not(SYSCLK) and (c0 and irop(0) and (irop(2) nor irop(1)));
				Bus2Dst(0)	<= '0';
			when 16 to 23 =>
				-- 000100YY LD  [imm16], dst
				-- 000101YY ST  src, [imm16]
				Mem_WR		<= c2 and irop(2);
				PChold		<= c2;
				DstBus2Mem	<= c2 and irop(2);
				if ((c0 or c1) = '1') then
					DstSel	<= "10" & c1; -- first immaLo then immaHi
				end if;
				Bus2Dst(1)	<= not(c3); -- data := MemBus
				Bus2Dst(0)	<= '0';
			when 24 to 31 =>
				-- 000110YY LD  [imm8], dst	(Zeropage)
				-- 000111YY ST  src, [imm8]	(Zeropage)
				Mem_WR		<= c1 and irop(2);
				PChold		<= c1;
				DstBus2Mem	<= c1 and irop(2);
				if (c0 = '1') then
					DstSel	<= "100"; -- immaLo
				end if;
				Bus2Dst(1)	<= not(c2); -- data := MemBus
				Bus2Dst(0)	<= '0';
			when 32 to 47 =>
				-- 0010XXYY LD [imm8:reg], dst
				Reg2addr		<= c1;
				if (c0 = '1') then
					DstSel	<= "101"; -- immaHi
				end if;
				Bus2Dst(1)	<= not(c2); -- data := MemBus
				Bus2Dst(0)	<= '0';
			when 48 to 63 =>
				-- 0011XXYY ST src, [imm8:reg]
				Mem_WR		<= c0 and irop(1);
				Reg2addr		<= c0;
				DstBus2Mem	<= c0 and irop(1);
				DstSel(1)	<= '0';
				Bus2Dst(1)	<= c0 and not(irop(1));
				Bus2Dst(0)	<= '0';
			when 80 to 95 =>
				-- 010100YY SHR reg
				-- 010101YY SHL reg
				-- 010110YY RCR reg
				-- 010111YY RCL reg
				ALU_OP		<= "11" & irop(2);
				ALU_Cin		<= irop(3) and F_Carry;
				F_Store		<= '1';
				Bus2Dst		<= "01";  -- "01"  ALUBus2Dst
			when 64 to 79 | 96 to 103 => null;
			when 104 to 111 =>
				-- 011010YY INC reg
				-- 011011YY DEC reg
				ALU_OP		<= irop(2) & "00";
				F_Store		<= c0;
				ModSel		<= "110"; -- "110" ONE constant
				Bus2Dst		<= "01";  -- "01"  ALUBus2Dst
			when 112 to 127 =>
				-- 0111XXYY XOR src, dst
				ALU_OP		<= "011"; -- "011" XOR
				F_Store		<= '1';
				Bus2Dst		<= "01";  -- "01"  ALUBus2Dst
			when 192 to 207 =>
				-- 1100XXYY CMP src, dst
				ALU_OP		<= "100"; -- "100" SUB
				ALU_Cin		<= F_Carry;
				F_Store		<= c0;
			when 128 to 191 | 208 to 239 =>
				--   operand		ALU	Cin	Bus2Dst
				-- 1000xxxx ADD 	000	0		01
				-- 1001xxxx AND 	001	-		01
				-- 1010xxxx OR  	010	-		01
				-- 1011xxxx ADC 	000	1		01
				-- 1101xxxx SUB 	100	0		01
				-- 1110xxxx SBC 	100	1		01
				ALU_OP(2)	<= irop(6);
				ALU_OP(1)	<= irop(5) and (irop(5) xnor irop(4)) and nrop(6);
				ALU_OP(0)	<= irop(4) and (irop(5) xnor irop(4)) and nrop(6);
				ALU_Cin		<= irop(5) and F_Carry;
				F_Store		<= c0;
				Bus2Dst		<= '0' & c0;
			when 240 to 255 =>
				-- 1111xxxx MOV
				Bus2Dst(1)		<= (c0 and samereg);
				Bus2Dst(0)		<= not(samereg);
		end case;
	end process;
end arch;
