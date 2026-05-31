monitor_save:

save_prompt_length:
	ld hl, str_prompt_length
	call puts
	call get_hex16
	jr nc, save_prompt_source
	cp 'q'
	ret z
	jr save_prompt_length

save_prompt_source:
	ld b, h
	ld c, l
	ld hl, str_prompt_address
	call puts
	call get_hex16
	jr nc, save_write_byte
	cp 'q'
	ret z
	jr save_prompt_source

save_write_byte:
	ld a, (hl)
	call putc
	inc hl
	dec bc
	ld a, 0
	cp b
	jp nz, save_write_byte
	cp c
	jp nz, save_write_byte
	ret
