        .ADDR   0x80000
        MOVI    R8, start_message
        SYSCALL 1
cmdloop:
        MOVI    R0, 0
        MOVI    R1, keybuffer
        STB     R0, [R1]
draw_cmdline:
        MOVI    R8, prompt
        SYSCALL 1
        MOVI    R8, keybuffer
        SYSCALL 1
keyloop:
        SYSCALL 3
        SBTI    R8, 0
        JPZI    keyloop
        SBTI    R8, 92
        JPZI    keyloop
        SBTI    R8, 8
        JPZI    do_bs
        SBTI    R8, 127
        JPZI    do_bs
        SBTI    R8, 10
        JPZI    do_enter
        SBTI    R8, 13
        JPZI    do_enter
        SBTI    R0, 80
        JPNUI   draw_cmdline
        STB     R8, [R1]
        INC     R0
        INC     R1
        MOVI    R8, 0
        STB     R8, [R1]
        JPI     draw_cmdline
do_bs:
        DEC     R1
        DEC     R0
        JPUI    cmdloop
        MOVI    R2, 0
        STB     R2, [R1]
        JPI     draw_cmdline
do_enter:
        MOVI    R8, 10
        SYSCALL 0
        SBTI    R0, 0
        JPZI    cmdloop
        MOVI    R2, 0
        STB     R2, [R1]
        MOVI    R8, keybuffer
; exit
        MOVI    R9, cmd_exit
        CALLI   cmp_str
        JPZI    do_exit
; reg
        MOVI    R9, cmd_reg
        CALLI   cmp_str
        JPZI    do_reg
; ls
        MOVI    R9, cmd_ls
        CALLI   cmp_str
        JPZI    do_ls
        MOVI    R8, cmd_error1
        SYSCALL 1
        MOVI    R8, keybuffer
        SYSCALL 1
        MOVI    R8, cmd_error2
        SYSCALL 1
        JPI     cmdloop
do_exit:
        MOVI    R8, end_message
        SYSCALL 1
        HALT
do_reg:
        SYSCALL 20
        JPI     cmdloop
do_ls:
        SYSCALL 21
        JPI     cmdloop

        HALT

; DATA
start_message:
        .STRING "Welcome to Simple OS!\n"
prompt:
        .STRING "\033[2K\r> "
cmd_reg:
        .STRING "reg"
cmd_exit:
        .STRING "exit"
cmd_ls:
        .STRING "ls"
cmd_error1:
        .STRING "Command "
cmd_error2:
        .STRING " not found.\n"
end_message:
        .STRING "bye.\n\n"

; System Function
        .ADDR   0xB0000
cmp_str:
        PUSH    R0
        PUSH    R1
        PUSH    R2
        PUSH    R3
        MOV     R0, R8
        MOV     R1, R9
_cmp_loop:
        LDB     R2, [R0]
        LDB     R3, [R1]
        SBT     R2, R3
        JPNZI   _cmp_str_end
        SBTI    R2, 0
        JPZI    _cmp_str_end
        INC     R0
        INC     R1
        JPI     _cmp_loop
_cmp_str_end:
        POP     R3
        POP     R2
        POP     R1
        POP     R0
        RET

; Buffer
        .ADDR   0xC0000
keybuffer:
        .BYTE   0
