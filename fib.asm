; calculate fibonacci sequence
; 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, ...

.org	$0000

main:
	XOR A, A
	INC A
	MOV A, B

fibb:
	MOV A, C	; backup fib(n-1)
	MOV B, A	; move fib(n) to fib(n-1)
	ADD C, B	; create new fib(n)

output:
	ST  B, [$D077]	; output to bizzaport

	JNC fibb	; loop if fib(n) is less than 256

	JMP main
