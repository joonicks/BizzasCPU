library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity regbank is
port(
	SYSCLK,
	PChold,
	PCjrel:			in			std_logic;
	AdrSel:			in			std_logic_vector(1 downto 0);
	ModSel,
	DstSel:			in			std_logic_vector(2 downto 0);
	Bus2Dst:			in			std_logic_vector(1 downto 0);
	Dst2Mem:			in			std_logic;
	ALUBus:			in			std_logic_vector(7 downto 0);
	MemBus,
	ModBus:			inout		std_logic_vector(7 downto 0);
	DstBus:			buffer	std_logic_vector(7 downto 0);
	addrHi,
	addrLo:			buffer	std_logic_vector(7 downto 0);
	A, B,	C,	D:		out		std_logic_vector(7 downto 0);
	MRDEBUG:			out		std_logic_vector(15 downto 0)
	);
end regbank;

-- Logic Elements: 36 37 44 36(68) 100 97 94 84 107 203 194 167 183

architecture arch of regbank is
signal PC:		std_logic_vector(15 downto 0) := x"0000";
alias  PCHi:	std_logic_vector( 7 downto 0) is PC(15 downto 8);
alias  PCLo:	std_logic_vector( 7 downto 0) is PC( 7 downto 0);
signal MR:		std_logic_vector(15 downto 0);
alias  MRHi:	std_logic_vector( 7 downto 0) is MR(15 downto 8);
alias  MRLo:	std_logic_vector( 7 downto 0) is MR( 7 downto 0);
signal regA, regB, regC, regD, regE: std_logic_vector(7 downto 0);
alias  M7:		std_logic is MemBus(7);
signal TR:		std_logic_vector(15 downto 0);
begin	
	MemBus <= DstBus when Dst2Mem = '1' else "ZZZZZZZZ";

	-- "00": Address bus = PCHi:PCLo
	-- "01": Address bus = MRHi:MRLo			[imm16] [PR:imm8]
	-- "10": Address bus = regE:ModBus		[PR:reg]
	-- "11": Address bus = regC:regD
	addrLo <= PCLo		when AdrSel = "00" else
				 MRLo		when AdrSel = "01" else
				 ModBus	when AdrSel = "10" else
				 regD;
	addrHi <= PCHi		when AdrSel = "00" else
				 MRHi		when AdrSel = "01" else
				 regE		when AdrSel = "10" else
				 regC;
	
	-- debug outputs
	A <= regA;
	B <= regB;
	C <= regC;
	D <= regD;
	MRDEBUG <= MR;
	
	-- DstBus output is never actually used unless it is a register
	DstBus <=	regA	when DstSel = "000" else
					regB	when DstSel = "001" else
					regC	when DstSel = "010" else
					regD;
	
	ModBus <=	regA		when ModSel = "000" else
					regB		when ModSel = "001" else
					regC		when ModSel = "010" else
					regD		when ModSel = "011" else
					MemBus	when ModSel = "100" else
					MRLo		when ModSel = "101" else
					regE		when ModSel = "110" else
					"00000001";

	TR <= ((addrHi & addrLo) + (M7 & M7 & M7 & M7 & M7 & M7 & M7 & M7 & MemBus)) when PCjrel = '1' else
			((addrHi & addrLo) + 1);
			
	process(SYSCLK, PCjrel, PChold, Membus, Bus2Dst, DstSel, ModSel)
		variable data: std_logic_vector(7 downto 0);
	begin
		if (rising_edge(SYSCLK)) then
			-- if PCjrel=1: PC = PC + MemBus
			-- if PChold=1: PC = PC
			-- if PChold=1: PC = PC + 1
			--if (PCjrel = '1') then
			--	PC <= PC + (M7 & M7 & M7 & M7 & M7 & M7 & M7 & M7 & MemBus);
			--els
			if (PChold = '0') then
			   if (AdrSel /= "00") then
					MR <= PC; -- if jumping, copy PC to MR first
				end if;
				PC <= TR;
			end if;

			if (Bus2Dst /= "00") then
				case Bus2Dst is
				when "00" => data := ModBus; -- Cant happen
				when "01" => data := ALUBus;
				when "10" => data := MemBus;
				when "11" => data := ModBus;
				end case;
				
				case DstSel is
				when "000" => regA <= data;
				when "001" => regB <= data;
				when "010" => regC <= data;
				when "011" => regD <= data;
				when "100" =>   MR <= "00000000" & data;
				when "101" => MRHi <= data;
				when "110" => regE <= data;
				when "111" =>
					if (Bus2Dst = "01") then
						-- no instructions ever copy ALUBus->MR
						-- used for opcode 48: MOV MR, C:D
						regC <= MRHi;
						regD <= MRLo;
					else
						MR <= regE & data;
					end if;
				end case;
			end if;
		end if;
	end process;	
end arch;
