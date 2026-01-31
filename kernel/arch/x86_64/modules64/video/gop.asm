; GOP (Graphics Output) - render 80x25 text buffer to UEFI framebuffer
; R14 = boot_info ptr (on stack), R15 = kernel base. display_base, cursor_* at [r15+offset].

section .rodata
align 8
; VGA 16-color palette as 32-bit BGRA
gop_palette:
    dd 0x000000, 0x0000AA, 0x00AA00, 0x00AAAA
    dd 0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA
    dd 0x555555, 0x5555FF, 0x55FF55, 0x55FFFF
    dd 0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF

; 8x8 font: 96 entries. Indices 0-94 = ASCII 32-126 (from font_8x8.inc), index 95 = block (cursor).
gop_font:
%include "modules64/video/font_8x8.inc"
gop_font_block:   ; index 95 = solid block for cursor
    db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

section .text
; render_buffer_to_gop: draw [display_base] to GOP framebuffer. 80x25 cells, 8x8 px each, 32bpp.
render_buffer_to_gop:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15                             ; [rsp] = kernel base (PIC)
    mov rax, r14                         ; boot_info ptr (on stack)
    mov ebx, [rax]
    cmp ebx, BOOT_INFO_MAGIC
    jne .out
    mov r12, [rax + 4]
    test r12, r12
    jz .out
    mov r13d, [rax + 0Ch]                ; pitch
    mov r14d, [rax + 10h]                ; width
    mov rbp, [r15 + DISPLAY_BASE_OFF]
    mov r15d, [rax + 14h]                ; height (r15 now = height)
    mov eax, r14d
    sub eax, 640
    shr eax, 1
    mov r10d, eax                        ; offset_x
    mov eax, r15d
    sub eax, 200
    shr eax, 1
    mov r11d, eax                        ; offset_y
    xor r8, r8                           ; row 0..24
.cell_row:
    xor r9, r9                           ; col 0..79
.cell_col:
    mov eax, r8d
    imul eax, 80
    add eax, r9d
    shl eax, 1                           ; offset in buffer
    mov ecx, eax
    mov rax, [rsp]
    cmp qword [rax + CURSOR_POS_OFF], rcx
    jne .no_cursor
    cmp byte [rax + CURSOR_VIS_OFF], 1
    jne .no_cursor
    lea rsi, [rel gop_font_block]
    jmp .got_font
.no_cursor:
    movzx eax, word [rbp + rcx]
    movzx ebx, ah                        ; attr
    movzx ecx, al                        ; char
    sub ecx, 32
    jns .idx_ok
    xor ecx, ecx
.idx_ok:
    cmp ecx, 95
    jbe .idx_ok2
    mov ecx, 95
.idx_ok2:
    imul ecx, 8
    lea rsi, [rel gop_font]
    add rsi, rcx
.got_font:
    movzx edx, bl
    mov edi, edx
    and edx, 0x0F
    shr edi, 4
    and edi, 0x0F
    shl edx, 2
    shl edi, 2
    lea rax, [rel gop_palette]
    mov edx, [rax + rdx]                 ; fg color
    mov edi, [rax + rdi]                 ; bg color
    xor r14, r14                         ; dy
.pixel_row:
    movzx eax, byte [rsi + r14]
    xor r15, r15                         ; dx
.pixel_col:
    mov ecx, 7
    sub ecx, r15d
    mov ebx, eax
    shr ebx, cl
    and ebx, 1                            ; bit 0 or 1 (fg/bg)
    push rbx
    ; pixel_y = offset_y + row*8 + dy, pixel_x = offset_x + col*8 + dx
    mov ecx, r11d
    add ecx, r8d
    shl ecx, 3
    add ecx, r14d
    imul ecx, r13d                       ; pixel_y * pitch
    mov ebx, r10d
    add ebx, r9d
    shl ebx, 3
    add ebx, r15d
    ; address = fb + (pixel_y*pitch + pixel_x*4); x86-64 allows at most [base+index*scale+disp]
    lea eax, [ecx + ebx*4]
    mov rcx, r12
    add rcx, rax
    pop rbx
    test ebx, ebx
    jnz .write_fg
    mov [rcx], edi
    jmp .next_pixel
.write_fg:
    mov [rcx], edx
.next_pixel:
    inc r15
    cmp r15, 8
    jb .pixel_col
    inc r14
    cmp r14, 8
    jb .pixel_row
    inc r9
    cmp r9, 80
    jb .cell_col
    inc r8
    cmp r8, 25
    jb .cell_row
.out:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret
