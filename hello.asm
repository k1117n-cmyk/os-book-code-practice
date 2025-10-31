        MOVI    R8, hello_str
        SYSCALL 1
        RET

hello_str:
        .STRING "Hello, World!\n"
