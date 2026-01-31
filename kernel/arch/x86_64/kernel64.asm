; SOFIA OS - 64-bit Kernel for UEFI
; Main kernel file - 64-bit long mode version
; This file is loaded by UEFI bootloader at 0x100000

BITS 64
org 0x200000   ; Load address: must match bootloader KERNEL_LOAD_ADDRESS (2MB for OVMF)

; ============================================================
; Constants
; ============================================================
VGA_MEMORY equ 0xB8000
SCREEN_WIDTH equ 80
SCREEN_HEIGHT equ 25

; Bloque de datos en 0x8000 (no pila ni .bss; la pila falla tras el JMP). R15 = base.
BOOT_INFO_MAGIC  equ 0x534F4649   ; "SOFI"
DATA_BASE equ 0x8000
; Layout [r15+offset]: 0 boot_info(32), 32 SCREEN_BUFFER(4000), 4032 display_base(8), 4040 cursor_pos(8), 4048 cursor_visible(1), 4049 color_counter(1), 4050 current_bg_color(1)
%define SCREEN_BUF_OFF    32
%define DISPLAY_BASE_OFF  4032
%define CURSOR_POS_OFF    4040
%define CURSOR_VIS_OFF    4048
%define COLOR_CNT_OFF    4049
%define CURRENT_BG_OFF    4050

; ============================================================
; Entry Point
; ============================================================
start:
    and rsp, -16
    test rdi, rdi
    jz vga_start
    ; Fondo blanco por trozos (12 x 800*50) para no colgar
    mov rbx, rdi
    xor r8d, r8d
gop_chunk_loop:
    cmp r8d, 12
    jae gop_chunk_done
    mov rax, r8
    imul eax, 160000                 ; 800*50*4
    mov rdi, rbx
    add rdi, rax
    mov eax, 0x00FFFFFF
    mov ecx, 800 * 50
gop_inner_fill:
    mov dword [rdi], eax
    add rdi, 4
    loop gop_inner_fill
    inc r8d
    jmp gop_chunk_loop
gop_chunk_done:
    mov rdi, rbx
    ; Logo SOFIA: cada letra hecha de muchas (S de S, O de O, etc.). 5x5 celdas por letra, glifo 8x8.
    jmp gop_past_data
sofia_font:   ; 8x8 VGA-style: cada letra muy reconocible (S,O,F,I,A)
    db 0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00   ; S
    db 0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00   ; O
    db 0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0x00   ; F
    db 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00   ; I
    db 0x18,0x3C,0x66,0x7E,0x66,0x66,0x66,0x00   ; A
sofia_templates:   ; 5x5 por letra: bit=1 -> dibujar glifo (S,O,F,I,A)
    db 0x1F,0x10,0x1E,0x01,0x1F   ; S
    db 0x0E,0x11,0x11,0x11,0x0E   ; O
    db 0x1F,0x10,0x1E,0x10,0x10   ; F
    db 0x0E,0x04,0x04,0x04,0x0E   ; I
    db 0x0E,0x11,0x1F,0x11,0x11   ; A
gop_past_data:
    lea r11, [rel sofia_font]
    lea r14, [rel sofia_templates]
    ; Logo 464x80 px: 5x5 celdas de 16x16; cada celda = letra 8x8 escalada 2x para verse como S,O,F,I,A.
    mov eax, edx
    sub eax, 464
    shr eax, 1
    mov r12d, eax                     ; start_x
    mov eax, ecx
    sub eax, 80
    shr eax, 1
    add eax, 60                      ; más abajo
    mov r13d, eax                     ; start_y
    xor r8d, r8d                      ; letter 0..4
gop_letter_loop:
    cmp r8d, 5
    jae gop_logo_done
    xor r9d, r9d                      ; ty 0..4
gop_ty_loop:
    cmp r9d, 5
    jae gop_ty_done
    xor r10d, r10d                   ; tx 0..4
gop_tx_loop:
    cmp r10d, 5
    jae gop_tx_done
    ; ¿Celda encendida? template[letter*5+ty] bit (4-tx)
    mov eax, r8d
    imul eax, 5
    add eax, r9d
    movzx eax, byte [r14 + rax]
    mov r15d, 4
    sub r15d, r10d
    bt eax, r15d
    jnc gop_next_cell
    push r10                           ; guardar tx
    ; Dest = start_x + letter*96 + tx*16, start_y + ty*16 (celda 16x16; glifo 8x8 dibujado 2x = 16x16)
    mov eax, r8d
    imul eax, 96
    add eax, r12d
    mov r15d, r10d
    shl r15d, 4
    add eax, r15d
    push r12
    push r13
    mov r12d, eax                      ; dest_x
    mov eax, r9d
    shl eax, 4
    add eax, r13d
    mov r13d, eax                      ; dest_y
    ; Glifo 8x8 escalado 2x: cada píxel del glifo = bloque 2x2 para que la letra se vea clara (16x16 por celda)
    xor r15d, r15d                     ; gy 0..7
gop_gy_loop:
    cmp r15d, 8
    jae gop_glyph_done
    mov eax, r8d
    shl eax, 3
    add eax, r15d
    movzx eax, byte [r11 + rax]        ; row_byte
    xor r10d, r10d                     ; gx 0..7
gop_gx_loop:
    cmp r10d, 8
    jae gop_gx_done
    mov ecx, 7
    sub ecx, r10d
    bt eax, ecx
    jnc gop_gx_skip
    ; Bloque 2x2 en (dest_x+gx*2, dest_y+gy*2)
    push r15
    xor ecx, ecx                       ; dy 0..1
gop_dy_loop:
    cmp ecx, 2
    jae gop_dy_done
    xor edx, edx                       ; dx 0..1
gop_dx_loop:
    cmp edx, 2
    jae gop_dx_done
    ; py = dest_y + gy*2 + dy
    mov eax, [rsp]
    add eax, eax
    add eax, r13d
    add eax, ecx
    imul eax, esi
    ; px = dest_x + gx*2 + dx
    mov r15d, r12d
    add r15d, r10d
    add r15d, r10d
    add r15d, edx
    shl r15d, 2
    add eax, r15d
    mov r15, rbx
    add r15, rax
    mov dword [r15], 0x00000000
    inc edx
    jmp gop_dx_loop
gop_dx_done:
    inc ecx
    jmp gop_dy_loop
gop_dy_done:
    pop r15
gop_gx_skip:
    inc r10d
    jmp gop_gx_loop
gop_gx_done:
    inc r15d
    jmp gop_gy_loop
gop_glyph_done:
    pop r13
    pop r12
    pop r10                             ; restaurar tx
gop_next_cell:
    inc r10d
    jmp gop_tx_loop
gop_tx_done:
    inc r9d
    jmp gop_ty_loop
gop_ty_done:
    inc r8d
    jmp gop_letter_loop
gop_logo_done:
    ; Cursor 8x8 a la izquierda, debajo del logo con espacio. Logo termina en start_y+80; cursor en start_y+104, x=50
    mov eax, r13d
    add eax, 104
    imul eax, esi
    mov ecx, 50
    shl ecx, 2
    add eax, ecx
    mov r9, rbx
    add r9, rax                       ; r9 = base del cursor
    ; Dibujar cursor negro inicial
    xor r8d, r8d
gop_cur_row:
    cmp r8d, 8
    jae gop_cur_done
    xor r10d, r10d
gop_cur_col:
    cmp r10d, 8
    jae gop_cur_col_done
    mov eax, r8d
    imul eax, esi
    mov ecx, r10d
    shl ecx, 2
    add eax, ecx
    mov r14, r9
    add r14, rax
    mov dword [r14], 0x00000000
    inc r10d
    jmp gop_cur_col
gop_cur_col_done:
    inc r8d
    jmp gop_cur_row
gop_cur_done:
    ; Bucle: parpadear cursor (alternar negro/blanco)
    mov r8d, 0                        ; 0=negro, 1=blanco (toggle)
gop_main_loop:
    mov eax, 80000000                 ; retardo 80M para parpadeo mucho más lento
gop_delay1:
    dec eax
    jnz gop_delay1
    ; Color: r8d=0 -> 0 (negro), r8d=1 -> 0x00FFFFFF (blanco)
    mov r12d, r8d
    imul r12d, 0x00FFFFFF
    xor r10d, r10d
gop_blink_row:
    cmp r10d, 8
    jae gop_blink_done
    xor r11d, r11d
gop_blink_col:
    cmp r11d, 8
    jae gop_blink_col_done
    mov eax, r10d
    imul eax, esi
    mov ecx, r11d
    shl ecx, 2
    add eax, ecx
    mov r14, r9
    add r14, rax
    mov dword [r14], r12d
    inc r11d
    jmp gop_blink_col
gop_blink_col_done:
    inc r10d
    jmp gop_blink_row
gop_blink_done:
    xor r8d, 1
    mov eax, 80000000
gop_delay2:
    dec eax
    jnz gop_delay2
    jmp gop_main_loop

vga_start:
    mov r15, DATA_BASE
    mov qword [r15 + DISPLAY_BASE_OFF], VGA_MEMORY
    mov rdi, VGA_MEMORY
    mov rcx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x7020
    rep stosw
    
    call disable_blinking
    call disable_cursor
    call beep
    call draw_sofia_large
    call draw_subtitle
    
    mov qword [r15 + CURSOR_POS_OFF], (13 * SCREEN_WIDTH) * 2
    mov byte [r15 + CURSOR_VIS_OFF], 1
    mov byte [r15 + COLOR_CNT_OFF], 0
    mov byte [r15 + CURRENT_BG_OFF], 0x70
    
main_loop:
    cmp qword [r15 + DISPLAY_BASE_OFF], VGA_MEMORY
    je .skip_gop_render
    call render_buffer_to_gop
.skip_gop_render:
    cmp byte [r15 + CURSOR_VIS_OFF], 1
    je .draw_it
    call erase_cursor
    jmp .after_cursor
.draw_it:
    call draw_cursor
.after_cursor:
    
    ; Delay (keyboard in/out disabled in UEFI - can hang)
    mov rcx, 150000
.delay_loop:
    nop
    loop .delay_loop
    
    xor byte [r15 + CURSOR_VIS_OFF], 1
    jmp main_loop

; ============================================================
; Color Cycling Function (must be before keyboard module)
; ============================================================

; Cycle to next background color (called when TAB is pressed)
; Bullet-proof version with counter
cycle_background_color:
    push rax
    push rbx
    push rcx
    push rdi
    
    mov al, [r15 + COLOR_CNT_OFF]
    inc al
    cmp al, 4
    jl .counter_ok
    xor al, al
.counter_ok:
    mov [r15 + COLOR_CNT_OFF], al
    
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
    mov [r15 + CURRENT_BG_OFF], bl
    mov rdi, [r15 + DISPLAY_BASE_OFF]
    mov rcx, SCREEN_WIDTH * SCREEN_HEIGHT
    
.update_loop:
    ; Read character (low byte) - keep it
    mov al, [rdi]
    ; Write back: character + new color attribute
    mov ah, bl
    mov word [rdi], ax
    
    ; Next character (2 bytes)
    add rdi, 2
    loop .update_loop
    
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================
; Module Includes (64-bit versions)
; ============================================================

; Video modules
%include "modules64/video/vga.asm"
%include "modules64/video/cursor.asm"
%include "modules64/video/gop.asm"

; UI modules
%include "modules64/ui/logo.asm"

; Driver modules
%include "modules64/drivers/speaker.asm"
%include "modules64/drivers/keyboard.asm"

; ============================================================
; Data Section
; ============================================================
; When GOP: display_base = SCREEN_BUFFER. When VGA: display_base = VGA_MEMORY.
display_base:   dq VGA_MEMORY

section .bss
; Boot info buffer (same layout as UEFI 0x8000; filled from regs at entry)
boot_info:
    resd 1   ; +0x00 magic
    resq 1   ; +0x04 fb_base
    resd 1   ; +0x0C pitch
    resd 1   ; +0x10 width
    resd 1   ; +0x14 height
    resd 1   ; +0x18 bpp

SCREEN_BUFFER:  resb SCREEN_WIDTH * SCREEN_HEIGHT * 2   ; 80*25*2 = 4000

section .text
cursor_pos: dq 0
cursor_visible: db 1

; Color cycling system (with counter for stability)
color_counter: db 0         ; Counter 0-4
current_bg_color: db 0x70   ; Default: white/gray

; ============================================================
; Padding to 16KB (kernel grew with GOP font and modules)
; ============================================================
times 16384-($-$$) db 0
