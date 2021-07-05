
.org	$0000

main:
	MOV $01, A
	MOV A, B

.L0:	ADD A, B
	ADD B, A
	JNC .L0

	ADD $06, D
	CMP $17, D
	NOP $0000
	INC D
	DEC C
	LD  [$00:D], C
	LD  [$000C], C
	INC C
	ST  C, [$000C]
	ST  C, [$D077]
	JMP main
