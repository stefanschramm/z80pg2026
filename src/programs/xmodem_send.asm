include 'definitions.asm'
	
	org 0xa000

XMODEM_BLOCK_SIZE: equ 0x80
XMODEM_ACK: equ 0x06
XMODEM_NAK: equ 0x15
XMODEM_SOH: equ 0x01
XMODEM_EOT: equ 0x04

xmodem_send:
	; block number
	ld bc, 0
	push bc
xmodem_read_length:
	ld hl, str_xmodem_prompt_length
	call os_puts
	call os_get_hex16
	jr c, xmodem_read_length
	ld d, h
	ld e, l
xmodem_read_source:
	ld hl, str_xmodem_prompt_source
	call os_puts
	call os_get_hex16
	jr c, xmodem_read_source
	push hl
	; TODO: neccessary to save DE too?
	ld hl, str_xmodem_start_receiver
	call os_puts
	pop hl
xmodem_wait_for_nak:
	call os_getc
	cp 'q'
	jr z, xmodem_send_finished
	cp XMODEM_NAK
	jr nz, xmodem_wait_for_nak
xmodem_send_current_packet:
	ld a, XMODEM_SOH
	call os_putc
	; send block number and its complement
	pop bc
	ld a, c
	call os_putc
	xor 0xff
	call os_putc
	push bc
	ld b, XMODEM_BLOCK_SIZE
	; checksum
	ld c, 0
xmodem_next_byte:
	ld a, (hl)
	call os_putc
	inc hl
	add c
	ld c, a
	djnz xmodem_next_byte
	; send checksum
	ld a, c
	call os_putc
xmodem_read_ack_or_nak:
	call os_getc
	cp XMODEM_ACK
	jr z, xmodem_packet_transmit_success
	cp XMODEM_NAK
	jr nz, xmodem_read_ack_or_nak
	; retransmission requested - reset HL
	ld bc, 0x80
	and a ; clear carry
	sbc hl, bc
	jr xmodem_send_current_packet
xmodem_packet_transmit_success:
	pop bc
	inc bc
	push bc
	; TODO: track when finished - currently infinite loop
	jr xmodem_send_current_packet
xmodem_send_eot:
	ld a, XMODEM_EOT
	call os_putc
xmodem_read_eot_ack_or_nak:
	call os_getc
	cp XMODEM_NAK
	jr z, xmodem_send_eot
	cp XMODEM_ACK
	jr nz, xmodem_read_eot_ack_or_nak
xmodem_send_finished:
	pop bc
	ret

str_xmodem_prompt_length:
	db "\r\nLength (hex) > \0"

str_xmodem_prompt_source:
	db "\r\nAddress > \0"

str_xmodem_start_receiver:
	db "\r\nWaiting for receiver to initiate transfer.\r\nq: cancel\r\n\0"

