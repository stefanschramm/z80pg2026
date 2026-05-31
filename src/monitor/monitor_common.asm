include 'definitions.asm'

; Write character to serial output
; Input: A = character to send
; Output -
; Flags: -
; Clobbers: F
putc:
	push af
putc_wait_for_uart:
	in a, (UART_LSR)
	bit 5, a
	jp z, putc_wait_for_uart
	pop af
	; output character
	out (UART_THR), a
	ret

; Write 0-terminated string to serial output
; Input: HL = address of string
; Output: -
; Flags: -
; Clobbers: HL
puts:
	push af
puts_next:
	ld a, (hl)
	cp 0
	jr z, puts_end
	call putc
	inc hl
	jp puts_next
puts_end:
	pop af
	ret

; Read character from serial input
; Input: -
; Output: A = received character
; Flags: -
; Clobbers: F
getc:
	; wait for uart
	in a, (UART_LSR)
	bit 0, a
	jr z, getc
	; read character
	in a, (UART_RBR)
	ret

; Read character from serial input without blocking
; Input: -
; Output: A = received character
; Flags: Z = No input was available
; Clobbers: A, F
getc_noblock:
	; read character
	in a, (UART_LSR)
	bit 0, a
	jr z, noinput
	in a, (UART_RBR)
	ret
noinput:
	ld a, 0
	ret	

; Write newline (CR LF) to serial output
; Input: -
; Output: -
; Flags: -
; Clobbers: A, F
put_newline:
	ld a, '\r'
	call putc
	ld a, '\n'
	call putc
	ret

; Write byte in hexadecimal
; Input: A
; Output: -
; Flags: -
; Clobbers: A, C, D, E, IX
put_hex8:
	ld c, a
	srl a
	srl a
	srl a
	srl a
	call put_hex4
	ld a, c
	and 0x0f
	call put_hex4
	ret

; Write nibble in hexadecimal
; Input: A
; Output: -
; Flags: -
; Clobbers: A, D, E, IX
put_hex4:
	ld d, 0
	ld e, a
	ld ix, put_hex4_lookup
	add ix, de
	ld a, (ix + 0)
	call putc
	ret

put_hex4_lookup:
	db "0123456789abcdef"

; Read byte in hexadecimal
; Input: -
; Output: A
; Flags: C = 0: success, C = 1: invalid input
; Clobbers: H
get_hex8:
	call get_hex4
	ret c
	ld h, a
	; TODO: use rld
	sla h
	sla h
	sla h
	sla h
	call get_hex4
	ret c
	or h
	ret

; Read 16 bit value in hexadecimal
; Input: -
; Output: HL
; Flags: C = 0: success, C = 1: invalid input
; Clobbers: A, F
get_hex16:
	call get_hex8
	jr c, get_hex16_error_1
	push af
	call get_hex8
	jr c, get_hex16_error_2
	ld l, a
	pop af
	ld h, a
	ret
get_hex16_error_2:
	; fake pop
	inc sp
	inc sp
get_hex16_error_1:
	scf
	ret

; Read nibble in hexadecimal
; Input: -
; Output: A (lower 4 bits; higher 4 bits are 0)
; Flags: C = 0: success, C = 1: invalid input
; Clobbers: F
get_hex4:
	call getc
	cp 0x30
	jp nc, get_hex4_is_within_min
	scf
	ret
get_hex4_is_within_min:
	cp 0x67
	jp c, get_hex4_is_within_max
	scf
	ret
get_hex4_is_within_max:
	cp 0x3a
	jp c, parse_hex_digit
	cp 0x61
	jp nc, parse_hex_letter
	scf
	ret
parse_hex_digit:
	call putc
	sub 0x30
	and a ; CF = 0
	ret
parse_hex_letter:
	call putc
	sub 0x57
	and a ; CF = 0
	ret

; Pause some time
; Input: BC = length
; Output: -
; Clobbers: A, BC, F
pause:
	dec bc
	ld a, b
	or c
	jr nz, pause
	ret
