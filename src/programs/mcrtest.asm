include 'definitions.asm'

	org 0xa000

mcrtest:
	ld hl, str_mcrtest
	call os_puts
	; set initial pattern
	in a, (UART_MCR)
	and 11111011b
	or  00001000b
mcrtest_next:
	out (UART_MCR), a
	xor 00001100b
	ld d, a
	ld bc, 0x2000
	call pause
	call os_getc_noblock
	cp 'q'
	jr z, mcrtest_end
	ld a, d
	jr mcrtest_next
mcrtest_end:
	ld a, d
	or 00001100b
	out (UART_MCR), a
	ret

pause:
pause_loop:
	dec bc
	ld a, b
	or c
	jr nz, pause_loop
	ret

str_mcrtest:
	dm "\r\nq: exit\r\n\0"
