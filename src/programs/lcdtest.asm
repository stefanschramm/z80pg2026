; Example program for HD44780 compatible display connected to the Z80 PIO
;
; Wiring
; K: GND
; A: 220 Ohm resistor to VCC (+5V)
; V0: Voltage divider (center of potentiometer)
; PIO port A:
; RS:   D0 (L = instruction register, H = data register)
; R /W: D1 (L = write, H = read)
; E:    D2 (H = enable, L = not enabled)
; PIO port B: LCD data bus

include 'definitions.asm'

PIOAD: equ 0x00
PIOBD: equ 0x01
PIOAC: equ 0x02
PIOBC: equ 0x03
ESC: equ 0x1b

	org 0xa000

lcdtest:
	call init_pio

	ld hl, str_usage
	call os_puts

	; data length 8 bit, 2 lines, font 0
	ld a, 00111000b
	call lcd_write_instruction

	; clear display
	ld a, 00000001b
	call lcd_write_instruction

	; display on, cursor on, blinking on
	ld a, 00001111b 
	call lcd_write_instruction

	ld hl, str_testpattern
	call lcd_write_string

lcdtest_loop:
	call os_getc
	cp 'q'
	ret z
	cp 'c'
	jr z, lcdtest_clear
	cp '-'
	jr z, lcdtest_shift_left
	cp '+'
	jr z, lcdtest_shift_right
	cp 'a'
	jr z, lcdtest_cursor_left
	cp 'd'
	jr z, lcdtest_cursor_right
	cp 'w'
	jr z, lcdtest_write_data
	cp 'i'
	jr z, lcdtest_live_input
	jr lcdtest_loop
lcdtest_clear:
	ld a, 00000001b
	call lcd_write_instruction
	jr lcdtest_loop
lcdtest_shift_left:
	ld a, 00011000b
	call lcd_write_instruction
	jr lcdtest_loop
lcdtest_shift_right:
	ld a, 00011100b
	call lcd_write_instruction
	jr lcdtest_loop
lcdtest_cursor_left:
	ld a, 00010000b
	call lcd_write_instruction
	jr lcdtest_loop
lcdtest_cursor_right:
	ld a, 00010100b
	call lcd_write_instruction
	jr lcdtest_loop
lcdtest_write_data:
	ld hl, str_hello
	call lcd_write_string
	jr lcdtest_loop

lcdtest_live_input:
	call os_getc
	cp ESC
	jr z, lcdtest_loop
	call lcd_write_data
	jr lcdtest_live_input

; Input: A = byte to send to instruction register
lcd_write_instruction:
	out (PIOBD), a
	call lcd_pause
	ld a, 00000000b ; instruction register write
	out (PIOAD), a
	call lcd_pause
	ld a, 00000100b ; enable
	out (PIOAD), a
	call lcd_pause
	ld a, 00000000b ; not enable
	out (PIOAD), a
	call lcd_pause
	ret

; Input: A = byte to send to data register
lcd_write_data:
	out (PIOBD), a
	call lcd_pause
	ld a, 00000001b ; data register write
	out (PIOAD), a
	call lcd_pause
	ld a, 00000101b ; enable
	out (PIOAD), a
	call lcd_pause
	ld a, 00000001b ; not enable
	out (PIOAD), a
	call lcd_pause
	; reset to instruction register write
	ld a, 00000000b 
	out (PIOAD), a
	ret

lcd_write_string:
	ld a, (hl)
	cp 0
	ret z
	call lcd_write_data
	inc hl
	jr lcd_write_string

; Using fix pauses instead of reading the display's ready bit
lcd_pause:
	ld b, 0
	ld c, 0x20
lcd_pause_loop:
	dec bc
	ld a, b
	or c
	jr nz, lcd_pause_loop
	ret

init_pio:
	ld a, 0xcf ; bit mode (mode 3)
	out (PIOAC), a
	ld a, 0x00 ; all ports are output
	out (PIOAC), a
	ld a, 0xcf ; bit mode (mode 3)
	out (PIOBC), a
	ld a, 0x00 ; all ports are output
	out (PIOBC), a
	ret

str_testpattern:
	dm "AAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBCCCCCCCC"
	dm "DDDDDDDDEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFF\0"
	;   ^^^^^^^^^^^^^^^^
	; initial visible area
	; can be shifted left/right

str_hello:
	dm "Hello\0"

str_usage:
	dm "\r\n"
	dm "q: quit\r\n"
	dm "c: clear\r\n"
	dm "-: shift left\r\n"
	dm "+: shift right\r\n"
	dm "a: cursor left\r\n"
	dm "d: cursor right\r\n"
	dm "w: write \"Hello\"\r\n"
	dm "i: input live data (exit with ESC)\r\n"
	db 0

