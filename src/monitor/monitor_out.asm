monitor_out:

out_prompt_port:
	ld hl, str_out_port_prompt
	call puts
	call get_hex8
	jr nc, out_prompt_value
	cp 'q'
	ret z
	jr out_prompt_port

out_prompt_value:
	ld c, a
	ld hl, str_out_prompt_value
	call puts
	call get_hex8
	jr nc, out_write_to_port
	cp 'q'
	ret z
	jr out_prompt_value

out_write_to_port:
	out (c), a
	ret

str_out_port_prompt:
	db "\r\nPort > \0"

str_out_prompt_value:
	db "\r\nValue > \0"
