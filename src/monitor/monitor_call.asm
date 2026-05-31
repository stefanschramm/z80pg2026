monitor_call:

call_prompt_address:
	ld hl, str_prompt_address
	call puts
	call get_hex16
	jr nc, call_start
	cp 'q'
	ret z
	jr call_prompt_address

call_start:
	; set return address explicitly
	ld bc, call_return
	push bc
	; simulate call to hl by push + ret
	push hl
	ret
	; called routine is expected to use ret - otherwise stack would not match
call_return:
	ret
