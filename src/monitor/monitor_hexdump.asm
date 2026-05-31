monitor_hexdump:

hexdump_prompt_address:
	ld hl, str_prompt_address
	call puts
	call get_hex16
	jr nc, hexdump_start
	cp 'q'
	ret z
	jr hexdump_prompt_address

hexdump_start:
	push hl
	ld hl, str_hexdump_usage
	call puts
	pop hl
	
hexdump_next_8_rows:
	ld b, 8
hexdump_next_row:
	call hexdump_print_row
	djnz hexdump_next_row
hexdump_input:
	call getc
	cp 'q'
	ret z
	cp ' '
	jr nz, hexdump_input
	jr hexdump_next_8_rows

hexdump_print_row:
	push bc
	push hl
	; print current address (hl)
	ld a, h
	call put_hex8
	ld a, l
	call put_hex8
	call hexdump_putc_space
	call hexdump_putc_space
	; 8 bytes
	ld b, 0x08
hexdump_next_byte:
	ld a, (hl)
	call put_hex8
	call hexdump_putc_space
	inc hl
	djnz hexdump_next_byte

	call hexdump_putc_space

	ld b, 0x08
hexdump_next_byte2:
	ld a, (hl)
	call put_hex8
	call hexdump_putc_space
	inc hl
	djnz hexdump_next_byte2

	call hexdump_putc_space

	ld a, '|'
	call putc

	pop hl
	ld b, 0x10
hexdump_next_byte_printable:
	ld a, (hl)
	call hexdump_putc_printable
	inc hl
	djnz hexdump_next_byte_printable

	ld a, '|'
	call putc

	push hl
	call put_newline
	pop hl
	pop bc
	ret

hexdump_putc_space:
	ld a, ' '
	call putc
	ret

hexdump_putc_printable:
	cp 0x20
	jr c, hexdump_putc_non_printable
	cp 0x7f
	jr nc, hexdump_putc_non_printable
	call putc
	ret
hexdump_putc_non_printable:
	ld a, '.'
	call putc
	ret

str_hexdump_usage:
	db "\r\n"
	db "space: continue\r\n"
	db "q: exit\r\n\0"

