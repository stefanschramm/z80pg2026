include 'definitions.asm'

	org 0xa000

XMODEM_BLOCK_SIZE: equ 0x80
XMODEM_ACK: equ 0x06
XMODEM_NAK: equ 0x15
XMODEM_SOH: equ 0x01
XMODEM_EOT: equ 0x04

xmodem_receive:
	; read destination address
	ld hl, str_xmodem_prompt_destination
	call os_puts
	call os_get_hex16
	jr c, xmodem_receive
	ld d, h
	ld e, l
	ld hl, str_xmodem_receive
	call os_puts
	call os_getc
	cp ' '
	ret nz
	; count blocks
	ld bc, 0
	push bc
xmodem_next_packet_nak:
	ld a, XMODEM_NAK
	call os_putc
xmodem_next_packet:
	call os_getc
	ld c, 0 ; checksum
xmodem_wait_soh:
	cp XMODEM_EOT
	jr z, xmodem_transmission_finished
	cp XMODEM_SOH
	jr nz, xmodem_wait_soh
	; read block number
	; TODO: check if expected block number
	call os_getc
	; read 1-complement of block number
	call os_getc
	; read 128 bytes of data
	ld b, XMODEM_BLOCK_SIZE
xmodem_next_byte:
	call os_getc
	ld (de), a
	inc de
	add c
	ld c, a
	djnz xmodem_next_byte
	; read checksum
	call os_getc
	cp c
	jr nz, xmodem_next_packet_nak
	; TODO: (re)set HL on retransmission request
	pop bc
	inc bc
	push bc
	ld a, XMODEM_ACK
	call os_putc
	jp xmodem_next_packet
xmodem_transmission_finished:
	ld a, XMODEM_ACK
	call os_putc
	ld hl, str_xmodem_done
	call os_puts
	pop bc
	ld a, c
	call os_put_hex8
	call os_put_newline
	ret

str_xmodem_prompt_destination:
	db "\r\nAddress > \0"

str_xmodem_receive:
	db "\r\nPress space to receive or any other key to cancel > \0"

str_xmodem_done:
	db "\r\nBlocks received (hex): \0"

