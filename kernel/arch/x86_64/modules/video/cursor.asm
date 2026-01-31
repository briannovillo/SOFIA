; Cursor Module
; Software cursor rendering

; Draw cursor (solid block)
draw_cursor:
    push eax
    push edi
    mov edi, VGA_MEMORY
    add edi, [cursor_pos]
    mov word [edi], 0x70DB      ; '█' solid block
    pop edi
    pop eax
    ret

; Erase cursor (space)
erase_cursor:
    push eax
    push edi
    mov edi, VGA_MEMORY
    add edi, [cursor_pos]
    mov word [edi], 0x7020      ; space
    pop edi
    pop eax
    ret
