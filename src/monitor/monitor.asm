OFFSET: equ 0x0000
; For development when executing monitor in RAM:
; OFFSET: equ 0x8000

RST_VECTORS: equ 0xf800

	org OFFSET

; reset vector contains jumps to locations in RAM to be flexible

rst00:
	jp main
	defs 5, 0x00
rst08:
	jp RST_VECTORS + 0x08
	defs 5, 0x00
rst10:
	jp RST_VECTORS + 0x10
	defs 5, 0x00
rst18:
	jp RST_VECTORS + 0x18
	defs 5, 0x00
rst20:
	jp RST_VECTORS + 0x20
	defs 5, 0x00
rst28:
	jp RST_VECTORS + 0x28
	defs 5, 0x00
rst30:
	jp RST_VECTORS + 0x30
	defs 5, 0x00
rst38:
	jp RST_VECTORS + 0x38
	defs 5, 0x00

; space for 12 functions in monitor jump table
; definitions.asm must be updated, when functions are added here
monitor_jumptable:
	jp putc
	jp getc
	jp getc_noblock
	jp puts
	jp put_newline
	jp put_hex8
	jp get_hex16
	; dummys reserved for later usage
	jp main
	jp main
	jp main
	jp main
	jp main

; not maskable interrupt (0x0066) will forward to 0xf840
nmi:
	jp RST_VECTORS + 0x40
	defs 5, 0x00

main:
	call init_uart
	call monitor_menu
	jp input_loop

init_uart:
	; disable all interrupts
	ld a, 0x00
	out (UART_IER), a
	; set DLAB on
	ld a, 0x80
	out (UART_LCR), a
	; divisor of 12 = 9600 bps with 1.8432 MHz clock (1843200 Hz / 16 / 12 = 9600 bps)
	; set LSB of divisor
	ld a, 12 
	out (UART_DLL), a
	; set MSB of divisor
	ld a, 00
	out (UART_DLM), a
	; 8 bits, 1 stop bit, no parity (and clear DLAB)
	ld a, 0x03
	out (UART_LCR), a

	; blink OUT1 / OUT2
	; off
	in a, (UART_MCR)
	or 00001100b
	out (UART_MCR), a
	ld c, 0
	ld b, 0x60
	call pause
	; on
	and 11110011b
	out (UART_MCR), a
	ld c, 0
	ld b, 0x60
	call pause
	; off
	or 00001100b
	out (UART_MCR), a

	ret

input_loop:
	ld hl, str_prompt
	call puts
	call getc
	cp 'a'
	jp nc, input_loop_within_min
	call monitor_unknown_command
	jp input_loop
input_loop_within_min:
	cp 'z' + 1
	jp c, input_loop_within_max
	call monitor_unknown_command
	jp input_loop
input_loop_within_max:
	call putc
	sub 'a'
	sla a ; one table entry takes 2 bytes
	ld hl, monitor_command_table
	ld b, 0
	ld c, a
	add hl, bc
	ld c, (hl)
	inc hl
	ld b, (hl)
	ld h, b
	ld l, c

	; fake call by manually putting return and target address onto stack
	ld bc, input_loop
	push bc
	push hl
	ret

	jp input_loop

monitor_unknown_command:
	ld hl, str_unknown_command
	call puts
	ret

default_rst_handler:
	ld hl, str_rst_called
	call puts
	ret

default_nmi_handler:
	ld hl, str_nmi_called
	call puts
	retn

; more complex monitor commands (having more input/output logic than these below)

include 'monitor_call.asm'
include 'monitor_hexdump.asm'
include 'monitor_hexedit.asm'
include 'monitor_in.asm'
include 'monitor_load.asm'
include 'monitor_out.asm'
include 'monitor_save.asm'

; simple monitor commands

monitor_halt:
	ld hl, str_halt
	call puts
	halt
	ret

monitor_menu:
	ld hl, str_menu
	call puts
	ret

monitor_reset:
	ld hl, str_reset
	call puts
	jp 0x0000
	ret

monitor_initialize_vectors:
	ld a, 0xc3 ; opcode for JP

	ld bc, default_rst_handler
	ld (RST_VECTORS + 0x08), a
	ld (RST_VECTORS + 0x08 + 1), bc
	ld (RST_VECTORS + 0x10), a
	ld (RST_VECTORS + 0x10 + 1), bc
	ld (RST_VECTORS + 0x18), a
	ld (RST_VECTORS + 0x18 + 1), bc
	ld (RST_VECTORS + 0x20), a
	ld (RST_VECTORS + 0x20 + 1), bc
	ld (RST_VECTORS + 0x28), a
	ld (RST_VECTORS + 0x28 + 1), bc
	ld (RST_VECTORS + 0x30), a
	ld (RST_VECTORS + 0x30 + 1), bc
	ld (RST_VECTORS + 0x38), a
	ld (RST_VECTORS + 0x38 + 1), bc

	ld bc, default_nmi_handler
	ld (RST_VECTORS + 0x40), a
	ld (RST_VECTORS + 0x40 + 1), bc

	ret

; 26 possible slots for monitor commands
monitor_command_table:
	; a
	dw monitor_unknown_command
	; b
	dw monitor_unknown_command
	; c
	dw monitor_call
	; d
	dw monitor_hexdump
	; e
	dw monitor_hexedit
	; f
	dw monitor_unknown_command
	; g
	dw monitor_unknown_command
	; h
	dw monitor_halt
	; i
	dw monitor_in
	; j
	dw monitor_unknown_command
	; k
	dw monitor_unknown_command
	; l
	dw monitor_load
	; m
	dw monitor_menu
	; n
	dw monitor_unknown_command
	; o
	dw monitor_out
	; p
	dw monitor_unknown_command
	; q
	dw monitor_unknown_command
	; r
	dw monitor_reset
	; s
	dw monitor_save
	; t
	dw monitor_unknown_command
	; u
	dw monitor_unknown_command
	; v
	dw monitor_initialize_vectors
	; w
	dw monitor_unknown_command
	; x
	dw monitor_unknown_command
	; y
	dw monitor_unknown_command
	; z
	dw monitor_unknown_command

str_menu:
	dm "\r\n\n"
	dm "-----------------------------------------\r\n"
	dm "Z80PG2026 monitor - "
	incbin 'version.inc.bin'
	dm "\r\n"
	dm "-----------------------------------------\r\n"
	dm "c: call address (input as hex number)\r\n"
	dm "d: hexdump\r\n"
	dm "e: hexedit\r\n"
	dm "h: halt system\r\n"
	dm "i: read byte from port (IN)\r\n"
	dm "l: load data\r\n"
	dm "m: show menu\r\n"
	dm "o: write byte to port (OUT)\r\n"
	dm "r: reset system\r\n"
	dm "s: save data\r\n"
	dm "v: set default RST/NMI handlers\r\n"
	dm "\0"

str_prompt:
	dm "\r\nCommand > \0"

str_prompt_address:
	db "\r\nAddress > \0"

str_prompt_length:
	db "\r\nLength > \0"

str_halt:
	dm "\r\nHalting system.\r\n\0"

str_reset:
	dm "\r\nResetting system.\r\n\r\n\0"

str_unknown_command:
	dm "\r\nUnknown command.\0"

str_rst_called:
	dm "\r\nDummy RST handler called.\r\n\0"

str_nmi_called:
	dm "\r\nDummy NMI handler called.\r\n\0"

include 'monitor_common.asm'

