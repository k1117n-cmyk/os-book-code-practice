	MOVI	R8, lmem_msg
	SYSCALL 1

	MOVI	R8, 0x30000	;論理アドレス
	MOVI	R9, 1
	SYSCALL	40

	MOVI	R8, pmem_msg
	SYSCALL 1

	MOVI	R8, 0x50000	;物理アドレス
	MOVI	R9, 0
	SYSCALL	40

	RET

lmem_msg:
	.STRING "[Logical Memory Dump]\n"
pmem_msg:
	.STRING "[Physical Memory Dump]\n"
