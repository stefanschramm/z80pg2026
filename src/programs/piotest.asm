include 'definitions.asm'

	PIOAD:	EQU 0x00
	PIOBD:	EQU 0x01
	PIOAC:	EQU 0x02
	PIOBC:	EQU 0x03

	org 0xa000

piotest:
	ld hl, str_piotest
	call os_puts
	call init_pio
	ld d, 0x20 ; default pause (high byte)
piotest_restart:
	ld a, 00000001b ; pattern
	out (PIOAD), a
piotest_loop:
	ld b, d
	ld c, 0x80
pause_loop:
	call os_getc_noblock
	cp '+'
	jr z, piotest_increment
	cp '-'
	jr z, piotest_decrement
	cp 'q'
	jr z, piotest_exit
	dec bc
	ld a, b
	or c
	jr nz, pause_loop
	in a, (PIOAD)
	rlca
	out (PIOAD), a
	jp piotest_loop
piotest_increment:
	inc d
	ld a, d
	push de
	call os_put_hex8
	pop de
	call os_put_newline
	jp piotest_restart
piotest_decrement:
	dec d
	ld a, d
	push de
	call os_put_hex8
	pop de
	call os_put_newline
	jp piotest_restart
piotest_exit:
	ld a, 0
	out (PIOAD), a
	ret


init_pio:
	ld a, 0xcf ; bit mode (mode 3)
	out (PIOAC), a
	ld a, 0x00 ; all ports are output
	out (PIOAC), a
	ret

str_piotest:
	dm "\r\n"
	dm "q: exit\r\n"
	dm "+: increase pause\r\n"
	dm "-: decrease pause\r\n"
	dm "\0"
