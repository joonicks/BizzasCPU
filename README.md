## Bizzas CPU

Direct decode instructions (Not microcode)

Main blocks:
```
		16-bit Address bus
		 8-bit Data bus

		8-bit ALU capable of doing CMP, ADD, ADC, SUB, SBC, XOR, AND, OR
		Four general purpose registers: A, B, C, D
		Non-user registers: IROP, INPC, IMMA
		Flags: Carry, Zero, Sign
```
Future blocks:
```
		IO/SPI/Serial
		Interrupts
		Instruction/Data cache
```
## Hobbyist CPU design

Primarily for Quartus (II)/Block diagrams & Schematics for the visual
(and possibly more educational) style.

First draft in VHDL

Initial goal is to get the CPU working on an FPGA with external RAM/ROM.

---

License: None / Open source

Project initiated by:

Alan Londa (Not real name)
in April 2018
