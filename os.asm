        .DEF    RUNNABLE     0
        .DEF    WAITING      1
        .DEF    TIMESLICE    5
        .DEF    T0_STACK_BTM 0xFF000
        .DEF    T1_STACK_BTM 0xF0000
        .DEF    T2_STACK_BTM 0xE8000
        .DEF    T3_STACK_BTM 0xE0000
        .DEF    T4_STACK_BTM 0xD8000
        .DEF    T0_PT        0xFFF00

        .ADDR   0x80000

; Task1 Setup
        MOVI    SP, T1_STACK_BTM
        MOVI    R0, 0
        PUSH    R0              ; PC
        MOVI    R0, 0x4000
        MULI    R0, 0x10000
        PUSH    R0              ; CR
        MOVI    R0, 0           ; dummy data
        PUSH    R0              ; R0
        PUSH    R0              ; R1
        PUSH    R0              ; R2
        PUSH    R0              ; R3
        PUSH    R0              ; R4
        PUSH    R0              ; R5
        PUSH    R0              ; R6
        PUSH    R0              ; R7
        PUSH    R0              ; R8
        PUSH    R0              ; R9
        PUSH    R0              ; PT
        MOVI    R0, vector_table
        PUSH    R0              ; VT
        STDI    SP, [_t1_sp]
; Task2 Setup
        MOVI    SP, T2_STACK_BTM
        MOVI    R0, 0
        PUSH    R0              ; PC
        MOVI    R0, 0x4000
        MULI    R0, 0x10000
        PUSH    R0              ; CR
        MOVI    R0, 0           ; dummy data
        PUSH    R0              ; R0
        PUSH    R0              ; R1
        PUSH    R0              ; R2
        PUSH    R0              ; R3
        PUSH    R0              ; R4
        PUSH    R0              ; R5
        PUSH    R0              ; R6
        PUSH    R0              ; R7
        PUSH    R0              ; R8
        PUSH    R0              ; R9
        PUSH    R0              ; PT
        MOVI    R0, vector_table
        PUSH    R0              ; VT
        STDI    SP, [_t2_sp]
; Task3 Setup
        MOVI    SP, T3_STACK_BTM
        MOVI    R0, 0
        PUSH    R0              ; PC
        MOVI    R0, 0x4000
        MULI    R0, 0x10000
        PUSH    R0              ; CR
        MOVI    R0, 0           ; dummy data
        PUSH    R0              ; R0
        PUSH    R0              ; R1
        PUSH    R0              ; R2
        PUSH    R0              ; R3
        PUSH    R0              ; R4
        PUSH    R0              ; R5
        PUSH    R0              ; R6
        PUSH    R0              ; R7
        PUSH    R0              ; R8
        PUSH    R0              ; R9
        PUSH    R0              ; PT
        MOVI    R0, vector_table
        PUSH    R0              ; VT
        STDI    SP, [_t3_sp]
; Task4 Setup
        MOVI    SP, T4_STACK_BTM
        MOVI    R0, idle_loop
        PUSH    R0              ; PC
        MOVI    R0, 0xC000
        MULI    R0, 0x10000
        PUSH    R0              ; CR
        MOVI    R0, 0           ; dummy data
        PUSH    R0              ; R0
        PUSH    R0              ; R1
        PUSH    R0              ; R2
        PUSH    R0              ; R3
        PUSH    R0              ; R4
        PUSH    R0              ; R5
        PUSH    R0              ; R6
        PUSH    R0              ; R7
        PUSH    R0              ; R8
        PUSH    R0              ; R9
        MOVI    R0, T0_PT
        PUSH    R0              ; PT
        MOVI    R0, vector_table
        PUSH    R0              ; VT
        STDI    SP, [_t4_sp]
; Start Task0
        MOVI    SP, T0_STACK_BTM
        STDI    SP, [_t0_sp]
        MOVI    R0, 0
        STBI    R0, [current_task]
        JPI     os_start
idle_loop:
        JPI     idle_loop

os_start:
        SYSCALL 10
        STDI    R8, [basetime]
        MOVI    TP, 0
        MOVI    VT, vector_table
        MOVI    PT, T0_PT
        MOVI    R0, 0xC000
        MULI    R0, 0x10000
        MOV     CR, R0          ; EI + MMU on
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
        CALLI   key_input
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

_sleep_proc:
        PUSH    R0
        PUSH    R1
        PUSH    R2
        PUSH    R3
        MOVI    R1, task_sleep_ticks
        MOVI    R2, task_status
        MOVI    R3, 0
_sleep_proc_loop:
        LDW     R0, [R1]
        SBTI    R0, 0
        JPZI    _next_task
        DEC     R0
        STW     R0, [R1]
        SBTI    R0, 0
        JPNZI   _next_task
        MOVI    R0, RUNNABLE
        STB     R0, [R2]
_next_task:
        INC     R3
        SBTI    R3, 4
        JPZI    _sleep_proc_end
        ADDI    R1, 2
        INC     R2
        JPI     _sleep_proc_loop
_sleep_proc_end:
        POP     R3
        POP     R2
        POP     R1
        POP     R0

_timeslice_proc:
        PUSH    R0
        PUSH    R1
        LDDI    R0, [basetick]
        SBTI    R0, 0
        JPNZI   _check_timeslice
        MOV     R0, TP
        STDI    R0, [basetick]
_check_timeslice:
        MOV     R1, TP
        SUB     R1, R0
        SBTI    R1, TIMESLICE
        JPUI    _no_task_switch
        MOVI    R0, 0
        STDI    R0, [basetick]
        POP     R1
        POP     R0
        JPI     _task_switch
_no_task_switch:
        POP     R1
        POP     R0
        IRET

_task_switch:
        PUSH    R0
        PUSH    R1
        PUSH    R2
        PUSH    R3
        PUSH    R4
        PUSH    R5
        PUSH    R6
        PUSH    R7
        PUSH    R8
        PUSH    R9
        PUSH    PT
        PUSH    VT
_save_sp:
        LDBI    R0, [current_task]
        MOV     R1, R0
        MULI    R1, 4
        ADDI    R1, task_stack_pointer
        STD     SP, [R1]

        MOVI    R2, 0
        INC     R0
        MODI    R0, 4
_find_loop:
        MOVI    R1, task_status
        ADD     R1, R0
        LDB     R3, [R1]
        SBTI    R3, RUNNABLE
        JPZI    _select_next
        INC     R2
        SBTI    R2, 4
        JPUI    _another_cand
        MOVI    R0, 4
        JPI     _select_next
_another_cand:
        INC     R0
        MODI    R0, 4
        JPI     _find_loop
_select_next:
        STBI    R0, [current_task]
        MOV     R8, R0
        SYSCALL 30
        MULI    R0, 4
        ADDI    R0, task_stack_pointer
        LDD     SP, [R0]
_int_timer_end:
        POP     VT
        POP     PT
        POP     R9
        POP     R8
        POP     R7
        POP     R6
        POP     R5
        POP     R4
        POP     R3
        POP     R2
        POP     R1
        POP     R0
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
basetick:
        .DWORD  0

; Task DATA
current_task:
        .BYTE   0

task_status:
_t0_status:
        .BYTE   RUNNABLE
_t1_status:
        .BYTE   WAITING
_t2_status:
        .BYTE   WAITING
_t3_status:
        .BYTE   WAITING
_t4_status:
        .BYTE   WAITING

task_sleep_ticks:
_t0_sleep_ticks:
        .WORD   0
_t1_sleep_ticks:
        .WORD   0
_t2_sleep_ticks:
        .WORD   0
_t3_sleep_ticks:
        .WORD   0
_t4_sleep_ticks:
        .WORD   0

task_stack_pointer:
_t0_sp:
        .DWORD  0
_t1_sp:
        .DWORD  0
_t2_sp:
        .DWORD  0
_t3_sp:
        .DWORD  0
_t4_sp:
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
        PUSH    R1
        LDBI    R0, [current_task]
        MOV     R1, R0
        MULI    R1, 2
        ADDI    R1, task_sleep_ticks
        MULI    R8, 10
        STW     R8, [R1]
        ADDI    R0, task_status
        MOVI    R8, WAITING
        STB     R8, [R0]
        POP     R1
        POP     R0
        MOVI    R8, _sleep_end
        PUSH    R8      ; PC
        PUSH    CR
        DI
        JPI     _task_switch
_sleep_end:
        RET

        .ADDR   0xB3000
key_input:
        SYSCALL 3
        SBTI    R8, 0
        JPNZI   _got_key
_do_yield:
        MOVI    R8, _resume_point
        PUSH    R8
        PUSH    CR
        DI
        JPI     _task_switch
_resume_point:
        SYSCALL 3
        SBTI    R8, 0
        JPZI    _do_yield
_got_key:
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
