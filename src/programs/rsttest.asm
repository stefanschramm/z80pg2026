include 'definitions.asm'

	org 0xa000

	ld hl, str_message
	call os_puts

	rst 0x08

	rst 0x10

	rst 0x18

	rst 0x20

	rst 0x28

	rst 0x30

	rst 0x38

	ld hl, str_message_finished
	call os_puts

	ret

str_message:
	db "\r\nGenerating RST from 0x08 to 0x38\r\n\0"

str_message_finished:
	db "\r\nFinished\r\n\0"
