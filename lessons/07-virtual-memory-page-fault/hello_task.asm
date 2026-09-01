	.DEF	sleep 0xB2000

	MOVI	R8, hello_str
	SYSCALL 1
	MOVI	R8, 600
	CALLI	sleep
loop:
	JPI	loop
hello_str:
	.STRING "Hello, World!\n"
