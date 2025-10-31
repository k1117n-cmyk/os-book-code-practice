        MOVI    R0, 0x12345

        MOVI    R8, msg1
        SYSCALL 1
        STDI    R0, [0x23000]

        MOVI    R8, msg2
        SYSCALL 1
        LDDI    R1, [0x23000]

        MOV     R8, R1
        MOVI    R9, fmt_str
        SYSCALL 2
        MOVI    R8, 10
        SYSCALL 0
        RET
msg1:
        .STRING "STDI   R0, [0x23000]\n"
msg2:
        .STRING "LDDI   R0, [0x23000]\n"

fmt_str:
        .STRING "05X"
