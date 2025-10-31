        MOVI    R0, 0
        MOVI    R1, 1
loop_start:
        SBTI    R1, 11
        JPZI    prog_end
        ADD     R0, R1
        INC     R1
        JPI     loop_start
prog_end:
        HALT
