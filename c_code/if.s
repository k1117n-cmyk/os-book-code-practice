	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_check                          ; -- Begin function check
	.p2align	2
_check:                                 ; @check
	.cfi_startproc
; %bb.0:
	cmp	w0, #0
	cset	w0, eq
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
