        MOVI    R8, hello_str
        SYSCALL 1
        HALT

hello_str:
        .STRING "Hello, World!\n"
