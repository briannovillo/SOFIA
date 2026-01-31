; SOFIA OS - Modular Kernel
; Main kernel file - includes all modules
; This file is loaded directly at 0x100000

BITS 32

; ============================================================
; Constants
; ============================================================
VGA_MEMORY equ 0xB8000
SCREEN_WIDTH equ 80
SCREEN_HEIGHT equ 25

; ============================================================
; Entry Point
; ============================================================
start:
    ; Clear VGA screen with WHITE background and BLACK text
    mov edi, VGA_MEMORY
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x7020      ; Black text (0x0) on white background (0x7) - no blink
    rep stosw
    
    ; Disable text blinking (fixes flickering on real hardware)
    call disable_blinking
    
    ; Disable hardware VGA cursor
    call disable_cursor
    
    ; Play startup beep
    call beep
    
    ; Draw large SOFIA logo (each letter made of itself)
    call draw_sofia_large
    
    ; Draw subtitle
    call draw_subtitle
    
    ; Set software cursor position (line 13, column 0)
    mov dword [cursor_pos], (13 * SCREEN_WIDTH) * 2
    mov byte [cursor_visible], 1
    
    ; Main loop with keyboard input and blinking cursor
main_loop:
    ; Draw cursor
    cmp byte [cursor_visible], 1
    je .draw_it
    call erase_cursor
    jmp .after_cursor
.draw_it:
    call draw_cursor
.after_cursor:
    
    ; Check keyboard multiple times during delay
    mov ecx, 4000       ; Check keyboard this many times
.kb_loop:
    push ecx
    call check_keyboard
    
    ; Small delay between checks
    mov ecx, 200000
.small_delay:
    nop
    loop .small_delay
    
    pop ecx
    loop .kb_loop
    
    ; Toggle cursor visibility
    xor byte [cursor_visible], 1
    
    jmp main_loop

; ============================================================
; Color Cycling Function (must be before keyboard module)
; ============================================================

; Cycle to next background color (called when TAB is pressed)
; Changes entire screen background color
cycle_background_color:
    push eax
    push ebx
    push ecx
    push edi
    
    ; Increment counter (0-3) - reduced to 4 light colors only
    mov al, [color_counter]
    inc al
    cmp al, 4
    jl .counter_ok
    xor al, al  ; Reset to 0
.counter_ok:
    mov [color_counter], al
    
    ; Convert counter to color value (only light backgrounds)
    cmp al, 0
    jne .not_0
    mov bl, 0x70  ; White/gray
    jmp .update_screen
.not_0:
    cmp al, 1
    jne .not_1
    mov bl, 0xB0  ; Cyan light
    jmp .update_screen
.not_1:
    cmp al, 2
    jne .not_2
    mov bl, 0xE0  ; Yellow light
    jmp .update_screen
.not_2:
    mov bl, 0x60  ; Beige/brown light
    
.update_screen:
    ; Save new color
    mov [current_bg_color], bl
    
    ; Update entire screen with new background color
    ; Loop through all VGA memory and change only the attribute byte (high byte)
    mov edi, VGA_MEMORY
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    
.update_loop:
    ; Read character (low byte) - keep it
    mov al, [edi]
    ; Write back: character + new color attribute
    mov ah, bl
    mov word [edi], ax
    
    ; Next character (2 bytes)
    add edi, 2
    loop .update_loop
    
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

; ============================================================
; Module Includes
; ============================================================

; Video modules
%include "modules/video/vga.asm"
%include "modules/video/cursor.asm"

; UI modules
%include "modules/ui/logo.asm"

; Driver modules
%include "modules/drivers/speaker.asm"
%include "modules/drivers/keyboard.asm"

; ============================================================
; Data Section
; ============================================================
cursor_pos: dd 0
cursor_visible: db 1

; Color cycling system (with counter for stability)
color_counter: db 0         ; Counter 0-4
current_bg_color: db 0x70   ; Default: white/gray

; ============================================================
; Padding to 4KB
; ============================================================
times 4096-($-$$) db 0
