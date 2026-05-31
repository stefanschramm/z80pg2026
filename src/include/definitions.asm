UART_BASE: equ 0x10
UART_RBR:  equ UART_BASE + 0x00
UART_THR:  equ UART_BASE + 0x00
UART_IER:  equ UART_BASE + 0x01
UART_IIR:  equ UART_BASE + 0x02
UART_FCR:  equ UART_BASE + 0x02
UART_LCR:  equ UART_BASE + 0x03
UART_MCR:  equ UART_BASE + 0x04
UART_LSR:  equ UART_BASE + 0x05
UART_MSR:  equ UART_BASE + 0x06
UART_SCR:  equ UART_BASE + 0x07
; when DLAB = 1:
UART_DLL:  equ UART_BASE + 0x00
UART_DLM:  equ UART_BASE + 0x01

RAMBEG: equ 0x8000
RAMEND: equ 0xffff

os_jumptable:    equ 0x0040
; For development when executing monitor in RAM:
; os_jumptable:  equ 0x8040
os_putc:         equ os_jumptable + 3 * 0
os_getc:         equ os_jumptable + 3 * 1
os_getc_noblock: equ os_jumptable + 3 * 2
os_puts:         equ os_jumptable + 3 * 3
os_put_newline:  equ os_jumptable + 3 * 4
os_put_hex8:     equ os_jumptable + 3 * 5
os_get_hex16:    equ os_jumptable + 3 * 6
