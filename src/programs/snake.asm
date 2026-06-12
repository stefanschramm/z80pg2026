include 'definitions.asm'

ESC:                  equ 0x1b
SNAKE_HEAD:           equ '@'
SNAKE_BODY:           equ 'O'
SNAKE_CROSS:          equ 'X'
COLLECTIBLE:          equ '*'
BORDER_LEFT:          equ 2
BORDER_RIGHT:         equ 79
BORDER_TOP:           equ 2
BORDER_BOTTOM:        equ 23
BORDER_CORNER:        equ '+'
BORDER_VERTICAL:      equ '|'
BORDER_HORIZONTAL:    equ '-'
GAME_STATE_RUNNING:   equ 1
GAME_STATE_GAME_OVER: equ 2
PAUSE_LENGTH:         equ 20 ; needs to be adjusted to cpu clock

    org 0xa000

snake:
    call cursor_hide
    call start_game
    call clear_screen
    call cursor_show
    ret

start_game:
    call initialize_state
    call clear_screen
    call draw_borders
    call draw_score
    call draw_collectible
main_loop:
    call process_input
    ret c
    call update_state
    call draw_snake
    call pause
    ld a, (game_state)
    cp GAME_STATE_RUNNING
    jr z, main_loop
    call draw_game_over_screen
main_loop_game_over:
    call os_getc
    cp 'r'
    jr z, start_game
    cp 'q'
    ret z
    jr main_loop_game_over

initialize_state:
    ld a, GAME_STATE_RUNNING
    ld (game_state), a
    ld bc, 0x0a0f
    ld (collectible_position), bc
    ld bc, 0x0004
    ld (snake_length_doubled), bc
    ld a, 0
    ld (snake_enlargement), a
    ld bc, 0x0001 ; right
    ld (snake_direction), bc
    ld bc, 0x0606
    ld (snake_fields + 0), bc
    dec c
    ld (snake_fields + 2), bc
    dec c
    ld (snake_fields + 4), bc
    ld a, r
    ld (random_seed), a
    call reposition_collectible
    ret

draw_borders:
    ; top
    ld b, BORDER_TOP
    ld c, BORDER_LEFT
    call cursor_yx
    ld a, BORDER_CORNER
    call os_putc
    ld b, BORDER_RIGHT - BORDER_LEFT - 1
    call draw_horizontal_line
    ld a, BORDER_CORNER
    call os_putc
    ; bottom
    ld b, BORDER_BOTTOM
    ld c, BORDER_LEFT
    call cursor_yx
    ld a, BORDER_CORNER
    call os_putc
    ld b, BORDER_RIGHT - BORDER_LEFT - 1
    call draw_horizontal_line
    ld a, BORDER_CORNER
    call os_putc
    ; left
    ld b, BORDER_TOP + 1
    ld c, BORDER_LEFT
    call cursor_yx
    ld b, BORDER_BOTTOM - BORDER_TOP - 1
    call draw_vertical_line
    ; right
    ld b, BORDER_TOP + 1
    ld c, BORDER_RIGHT
    call cursor_yx
    ld b, BORDER_BOTTOM - BORDER_TOP - 1
    call draw_vertical_line
    ret

process_input:
    ; Returns with carry flag set when exit was requested
    call os_getc_noblock
    cp 'q'
    jr z, input_quit
    cp 'w'
    jr z, input_up
    cp 'a'
    jr z, input_left
    cp 's'
    jr z, input_down
    cp 'd'
    jr z, input_right
    cp 'A'
    jr z, input_up
    cp 'B'
    jr z, input_down
    cp 'C'
    jr z, input_right
    cp 'D'
    jr z, input_left
    and a
    ret
input_quit:
    scf
    ret
input_up:
    ld a, -1
    ld (snake_direction_y), a
    ld a, 0
    ld (snake_direction_x), a
    ret
input_left:
    ld a, 0
    ld (snake_direction_y), a
    ld a, -1
    ld (snake_direction_x), a
    ret
input_down:
    ld a, 1
    ld (snake_direction_y), a
    ld a, 0
    ld (snake_direction_x), a
    ret
input_right:
    ld a, 0
    ld (snake_direction_y), a
    ld a, 1
    ld (snake_direction_x), a
    ret

update_state:
    call enlarge_snake
    call move_snake
    call process_collisions
    ret

enlarge_snake:
    ld a, (snake_enlargement)
    cp 0
    ret z

    dec a
    ld (snake_enlargement), a

    ld bc, (snake_length_doubled)
    inc bc
    inc bc
    ld (snake_length_doubled), bc
    ld hl, snake_fields
    add hl, bc
    ; copy tail
    ld b, h
    ld c, l
    dec bc
    dec bc
    ld a, (bc)
    ld (hl), a
    inc bc
    inc hl
    ld a, (bc)
    ld (hl), a
    call draw_score
    ret

move_snake:
    ; shift all snake_fields (from the end) by one location (= 2 bytes)
    ld bc, (snake_length_doubled)
    ld hl, snake_fields
    add hl, bc
    ld d, h
    ld e, l
    inc de
    ld hl, snake_fields
    add hl, bc
    dec hl
    lddr
    ; move head in specified direction
    ld bc, (snake_direction)
    ld a, (snake_fields)
    add c
    ld (snake_fields), a
    ld a, (snake_fields + 1)
    add b
    ld (snake_fields + 1), a
    ret

process_collisions:
    call process_collectible_collision
    call process_snake_collision
    call process_wall_collision
    ret

process_collectible_collision:
    ld a, (snake_fields)
    ld hl, collectible_position
    cp (hl)
    ret nz
    ld a, (snake_fields + 1)
    inc hl
    cp (hl)
    ret nz
    ld hl, snake_enlargement
    inc (hl)
    inc (hl)
    inc (hl)
    call reposition_collectible
    call draw_collectible
    ret

process_snake_collision:
    ld bc, (snake_length_doubled)
    ; -2 because we don't want to check the (invisible) tail
    dec bc
    dec bc
    ld de, (snake_fields) ; head
    ld hl, snake_fields + 2
process_snake_collision_next:
    ld a, (hl)
    cp e
    jr nz, process_snake_collision_no_collision_e
    inc hl
    ld a, (hl)
    cp d
    jr nz, process_snake_collision_no_collision_d
    ; collision
    ld a, GAME_STATE_GAME_OVER
    ld (game_state), a
    ret
process_snake_collision_no_collision_e:
    inc hl
process_snake_collision_no_collision_d:
    inc hl
    dec bc
    dec bc
    ld a, b
    or c
    jr nz, process_snake_collision_next
    ret

process_wall_collision:
    ld bc, (snake_fields)
    ld a, c
    cp BORDER_LEFT
    jr z, process_wall_collision_collided
    cp BORDER_RIGHT
    jr z, process_wall_collision_collided
    ld a, b
    cp BORDER_TOP
    jr z, process_wall_collision_collided
    cp BORDER_BOTTOM
    jr z, process_wall_collision_collided
    ret
process_wall_collision_collided:
    ld a, GAME_STATE_GAME_OVER
    ld (game_state), a
    ret

reposition_collectible:
reposition_collectible_get_column:
    call get_random_number
    cp BORDER_LEFT + 1
    jr c, reposition_collectible_get_column
    cp BORDER_RIGHT - 1
    jr nc, reposition_collectible_get_column
    ld c, a
reposition_collectible_get_row:
    call get_random_number
    cp BORDER_TOP + 1
    jr c, reposition_collectible_get_row
    cp BORDER_BOTTOM - 1
    jr nc, reposition_collectible_get_row
    ld b, a
    ld (collectible_position), bc
    ; check all snake_fields and prevent placing collectible there
    ld de, (collectible_position)
    ld bc, (snake_length_doubled)
    ld hl, snake_fields
reposition_collectible_check_next_snake_field:
    ld a, (hl)
    cp e
    jr nz, reposition_collectible_check_next_snake_field_x_differs
    inc hl
    ld a, (hl)
    cp d
    jr nz, reposition_collectible_check_next_snake_field_y_differs
    ; collectible got positioned at snake - try to reposition
    ; TODO: Limit number of retries (and end game)? It may get in an infinite loop otherwise.
    ; Instead of getting a new random number we could also (spiral-)search for the nearest empty field.
    jr reposition_collectible
reposition_collectible_check_next_snake_field_x_differs:
    inc hl
reposition_collectible_check_next_snake_field_y_differs:
    inc hl
    dec bc
    dec bc
    ld a, b
    or c
    jr nz, reposition_collectible_check_next_snake_field
reposition_collectible_finished:
    ret

pause:
	ld b, PAUSE_LENGTH
	ld c, 0
pause_loop:
	dec bc
	ld a, b
	or c
	jr nz, pause_loop
    ret

draw_score:
    ld b, BORDER_BOTTOM + 1
    ld c, BORDER_LEFT
    call cursor_yx
    ld hl, str_score
    call os_puts
    ld bc, (snake_length_doubled)
    ; -2 because snake always consist of a head and a body
    dec bc
    dec bc
    dec bc
    dec bc
    ; divide by 2
    srl b
    rr c
    push bc
    ld a, b
    call os_put_hex8
    pop bc
    ld a, c
    call os_put_hex8
    ret

draw_snake:
    ; head
    ld bc, (snake_fields)
    call cursor_yx
    ld a, SNAKE_HEAD
    call os_putc
    ; neck
    ld bc, (snake_fields + 2)
    call cursor_yx
    ld a, SNAKE_BODY
    call os_putc
    ; clear at tail
    ; There currently is a small glitch when the snake is being enlarged and
    ; the head enters the field behind the tail.
    ; Maybe we should skip clearing the tail when snake_enlargement is > 0.
    ld hl, snake_fields
    ld bc, (snake_length_doubled)
    add hl, bc
    ld c, (hl)
    inc hl
    ld b, (hl)
    call cursor_yx
    ld a, ' '
    call os_putc
    ret

draw_game_over_screen:
    ld bc, (snake_fields)
    call cursor_yx
    ld a, SNAKE_CROSS
    call os_putc
    ld b, BORDER_TOP + (BORDER_BOTTOM - BORDER_TOP) / 2
    ld c, BORDER_LEFT + (BORDER_RIGHT - BORDER_LEFT - str_game_over_length) / 2
    call cursor_yx
    ld hl, str_game_over
    call os_puts
    ld b, BORDER_BOTTOM + 1
    ld c, BORDER_RIGHT - str_game_over_keys_length + 1
    call cursor_yx
    ld hl, str_game_over_keys
    call os_puts
    ret

draw_collectible:
    ld bc, (collectible_position)
    call cursor_yx
    ld a, COLLECTIBLE
    call os_putc
    ret

draw_vertical_line:
    ld a, BORDER_VERTICAL
    call os_putc
    call cursor_down
    call cursor_left
    djnz draw_vertical_line
    ret

draw_horizontal_line:
    ld a, BORDER_HORIZONTAL
    call os_putc
    djnz draw_horizontal_line
    ret

clear_screen:
    ld hl, str_clear_screen
    call os_puts
    ret

cursor_down:
    ld hl, str_cursor_down
    call os_puts
    ret

cursor_left:
    ld hl, str_cursor_left
    call os_puts
    ret

cursor_yx:
    ; Input: C = x coordinate (column), B = y coordinate (line)
    push bc
    ld a, ESC
    call os_putc
    ld a, '['
    call os_putc
    ld a, b
    call put_decimal
    ld a, ';'
    call os_putc
    pop bc
    ld a, c
    call put_decimal
    ld a, 'H'
    call os_putc
    ret

cursor_hide:
    ld hl, str_cursor_hide
    call os_puts
    ret

cursor_show:
    ld hl, str_cursor_show
    call os_puts
    ret

put_decimal:
    ; Write decimal value (with leading zeros)
    ; Input: A = value to print
    ; Clobbers: A, B, C, F
    ld b, 0 ; x__
    ld c, 0 ; _x_
put_decimal_3:
    cp 100
    jr c, put_decimal_2
    sub 100
    inc b
    jr put_decimal_3
put_decimal_2:
    cp 10
    jr c, put_decimal_1
    sub 10
    inc c
    jr put_decimal_2
put_decimal_1:
    ld d, a ; __x
    ; print all digits; don't care about leading zeros
    ld a, b
    or 0x30
    call os_putc
    ld a, c
    or 0x30
    call os_putc
    ld a, d
    or 0x30
    call os_putc
    ret

get_random_number:
    ld a, (random_seed)
    and 0xb8
    scf
    jp po, get_random_number_no_clear
    ccf
get_random_number_no_clear:
    ld a, (random_seed)
    rla
    ld (random_seed), a
    ret

; https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#cursor-controls

str_clear_screen:
    db "\033[2J\0"

str_cursor_down:
    db "\033[B\0"

str_cursor_left:
    db "\033[D\0"

str_cursor_hide:
    db "\033[?25l\0"

str_cursor_show:
    db "\033[?25h\0"

str_score:
    db "Score: 0x\0"

str_game_over:
    db " G A M E   O V E R \0"
str_game_over_length: equ $ - str_game_over - 1

str_game_over_keys:
    db "q: quit, r: replay\0"
str_game_over_keys_length: equ $ - str_game_over_keys -1

; game state - initialization takes place in initialize_state

game_state:
    db 0

random_seed:
    db 0

collectible_position:
    dw 0

snake_length_doubled:
    dw 0

snake_enlargement:
    db 0

snake_direction:
snake_direction_x:
    db 0
snake_direction_y:
    db 0

; one field takes 2 bytes: x, y; first field is head of snake
snake_fields:
    dw 0
    dw 0
    dw 0
    ; ...rest of memory not reserved in program binary
