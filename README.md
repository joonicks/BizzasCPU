## Bizzas CPU

Direct decode instructions (Not microcode)

Main blocks:
```
		16-bit Address bus
		 8-bit Data bus
		 8-bit ALU

		Four general purpose registers: A, B, C, D
		Non-user registers: IROP (instruction register), INPC (program counter)
			and IMMA (memory address register), ONE (constant 1 register)
		Flags: Carry, Zero, Sign
```
Wishful thinking future blocks:
```
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

Initial goal is to get the CPU working on an FPGA with external RAM/ROM.

---

License: GPL v2

Project initiated by:

Alan Londa (Not real name), a.k.a. joonicks (may be found on Freenode)
in April 2018
