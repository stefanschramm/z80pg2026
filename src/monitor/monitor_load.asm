monitor_load:

load_prompt_length:
	ld hl, str_prompt_length
	call puts
	call get_hex16
	jr nc, load_prompt_destination
	cp 'q'
	ret z
	jr load_prompt_length

load_prompt_destination:
	ld b, h
	ld c, l
	ld hl, str_prompt_address
	call puts
	call get_hex16
	jr nc, load_read_byte
	cp 'q'
	ret z
	jr load_prompt_destination

load_read_byte:
	call getc
	ld (hl), a
	inc	hl
	dec bc
	ld a, 0
	cp b
	jp nz, load_read_byte
	cp c
	jp nz, load_read_byte
	ret
