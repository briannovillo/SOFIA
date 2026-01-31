; Cursor Module - 64-bit version
; Software cursor rendering

; Draw cursor (solid block) at display_base + cursor_pos
draw_cursor:
    push rax
    push rdi
    mov rdi, [r15 + DISPLAY_BASE_OFF]
    add rdi, [r15 + CURSOR_POS_OFF]
    mov word [rdi], 0x70DB      ; '█' solid block
    pop rdi
    pop rax
    ret

; Erase cursor (space)
erase_cursor:
    push rax
    push rdi
    mov rdi, [r15 + DISPLAY_BASE_OFF]
    add rdi, [r15 + CURSOR_POS_OFF]
    mov word [rdi], 0x7020      ; space
    pop rdi
    pop rax
    ret
