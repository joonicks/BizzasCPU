## Bizzas CPU

Direct decode instructions (Not microcode)

Main blocks:
```
		16-bit Address bus for 64Kb usable address space
		 8-bit Data bus
		 8-bit ALU

		Four general purpose registers: A, B, C, D
		Special registers: IR (instruction register (inaccessible)), PC (program counter),
			E (memory page pointer) and MR (memory address register)
		Flags: Carry, Zero, Sign
```
Wishful thinking future blocks:
```
		Ability to freeze execution at any time to accomodate external wait states
		Stack (unlikely)
		Interrupts
		Instruction/Data cache
```
## Name

BizzasCPU comes from an old webpage of mine where I had posted some concept Linux programs,
called "Bizarre Sources". Now this CPU design isnt meant to be hyper-useful, but rather
educational and an experiment in simplicity and efficiency.

## Hobbyist CPU design

Design started in Quartus II, the first two revisions were entirely block diagram based,
but that made development very slow and complex. Revision 3 started over with VHDL to make
design and implementation easier/faster.

## Goals

To develop a fully functional, easily programmable CPU while minimizing resource usage
(FPGA Logic Elements or other applicable units).

2021-06-04: Tested running small program successfully on a Terasic DE10-Nano.

---

License: GPL v2

Project initiated by:

Alan Londa (Not real name), a.k.a. joonicks
in April 2018
