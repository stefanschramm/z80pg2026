monitor_hexedit:

hexedit_prompt_address:
	ld hl, str_prompt_address
	call puts
	call get_hex16
	jr nc, hexedit_start
	cp 'q'
	ret z
	jr hexedit_prompt_address

hexedit_start:
	push hl
	ld hl, str_hexedit_usage
	call puts
	pop hl

hexedit_edit_byte:
	call put_newline
	; output address
	ld a, h
	call put_hex8
	ld a, l
	call put_hex8
	ld a, ' '
	; output previous data
	call putc
	ld a, (hl)
	call put_hex8
	ld a, ' '
	call putc
	push hl
	call get_hex8
	jr nc, hexedit_write_byte
	cp 'q'
	jr z, hexedit_exit
	cp '+'
	jr z, hexedit_proceed_to_next_byte
	cp '-'
	jr z, hexedit_return_to_previous_byte
	cp 'g'
	jr z, hexedit_prompt_new_address
	pop hl
	jr hexedit_edit_byte

hexedit_write_byte:
	pop hl
	ld (hl), a
	inc hl
	jp hexedit_edit_byte

hexedit_proceed_to_next_byte:
	pop hl
	inc hl
	jp hexedit_edit_byte

hexedit_return_to_previous_byte:
	pop hl
	dec hl
	jp hexedit_edit_byte

hexedit_prompt_new_address:
	pop hl
	jp hexedit_prompt_address

hexedit_exit:
	pop hl
	ret

str_hexedit_usage:
	db "\r\n"
	db "q: exit\r\n"
	db "g: jump to another address\r\n"
	db "+: skip to next byte\r\n"
	db "-: return to previous byte\0"
