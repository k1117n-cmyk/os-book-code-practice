        .ADDR   0x80000
        SYSCALL 10
        STDI    R8, [basetime]
        MOVI    TP, 0
        MOVI    VT, vector_table
        EI
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
        MOVI    R8, 1
        MOVI    R9, keybuffer
        CALLI   get_nth_token
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
; exec
        MOVI    R9, cmd_exec
        CALLI   cmp_str
        JPZI    do_exec
; date
        MOVI    R9, cmd_date
        CALLI   cmp_str
        JPZI    do_date

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
do_exec:
        MOVI    R8, 2
        MOVI    R9, keybuffer
        CALLI   get_nth_token
        SYSCALL 22
        JPI     cmdloop
do_date:
        LDDI    R8, [basetime]
        SYSCALL 11
        JPI     cmdloop

        HALT

; Handler
int_timer:
        INC     TP
int_other:
        IRET

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
cmd_exec:
        .STRING "exec"
cmd_date:
        .STRING "date"
cmd_error1:
        .STRING "Command "
cmd_error2:
        .STRING " not found.\n"
end_message:
        .STRING "bye.\n\n"
basetime:
        .DWORD  0

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

        .ADDR   0xB1000
get_nth_token:
        PUSH    R0
        PUSH    R1
        PUSH    R2
        PUSH    R3
        MOV     R0, R9
        MOVI    R1, 0
        MOVI    R2, 0
_get_token_addr:
_outer_loop:
        DEC     R8
        JPUI    _outer_loop_end
_inner_loop:
        LDB     R3, [R0]
        SBTI    R3, 9
        JPZI    _do_space
        SBTI    R3, 32
        JPZI    _do_space
        SBTI    R3, 0
        JPZI    _null_return
        SBTI    R2, 0
        JPNZI   _inner_loop_next
        NOT     R2
        MOV     R1, R0
        JPI     _inner_loop_end
_do_space:
        SBTI    R2, 0
        JPZI    _inner_loop_next
        NOT     R2
_inner_loop_next:
        INC     R0
        JPI     _inner_loop
_inner_loop_end:
        JPI     _outer_loop

_outer_loop_end:
        MOVI    R0, tokenbuffer
_copy_token:
        LDB     R2, [R1]
        STB     R2, [R0]
        SBTI    R2, 9
        JPZI    _cut_token
        SBTI    R2, 32
        JPZI    _cut_token
        SBTI    R2, 0
        JPZI    _get_nth_token_end
        INC     R0
        INC     R1
        JPI     _copy_token
_null_return:
        MOVI    R0, tokenbuffer
_cut_token:
        MOVI    R2, 0
        STB     R2, [R0]
_get_nth_token_end:
        POP     R3
        POP     R2
        POP     R1
        POP     R0
        MOVI    R8, tokenbuffer
        RET

        .ADDR   0xB2000
sleep:
        PUSH    R0
        MOV     R0, TP
        MULI    R8, 10
        ADD     R0, R8
_wait_loop:
        SBT     TP, R0
        JPUI    _wait_loop
        POP     R0
        RET

; Buffer
        .ADDR   0xC0000
keybuffer:
        .BYTE   0

        .ADDR   0xC1000
tokenbuffer:
        .BYTE   0

; Vector Table
        .ADDR   0xFF800
vector_table:
        .DWORD  int_timer
        .DWORD  int_other
        .DWORD  int_other
        .DWORD  int_other
