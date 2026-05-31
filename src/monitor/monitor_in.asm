monitor_in:

in_prompt_port:
	ld hl, str_in_prompt_port
	call puts
	call get_hex8
	jr nc, in_read_from_port
	cp 'q'
	ret z
	jr in_prompt_port

in_read_from_port:
	ld c, a
	call put_newline
	in a, (c)
	call put_hex8
	ret

str_in_prompt_port:
	db "\r\nPort > \0"

