; Keyboard Module
; PS/2 keyboard driver with scancode to ASCII mapping

; Check for keyboard input
check_keyboard:
    ; Check if keyboard data is available
    in al, 0x64
    test al, 1
    jz .no_key
    
    ; Read scancode from keyboard
    in al, 0x60
    
    ; Ignore key releases (high bit set)
    test al, 0x80
    jnz .no_key
    
    ; Save scancode
    mov cl, al
    
    ; Handle TAB - cycle background color
    cmp cl, 0x0F
    jne .not_tab
    call cycle_background_color
    jmp .no_key
.not_tab:
    
    ; Erase cursor before writing
    push eax
    push ebx
    mov edi, VGA_MEMORY
    add edi, [cursor_pos]
    movzx ebx, byte [current_bg_color]
    mov ah, bl
    mov al, 0x20  ; space
    mov word [edi], ax
    pop ebx
    pop eax
    
    ; Handle backspace
    cmp cl, 0x0E
    jne .not_bs
    cmp dword [cursor_pos], (13 * SCREEN_WIDTH) * 2
    jle .no_key
    sub dword [cursor_pos], 2
    push eax
    push ebx
    mov edi, VGA_MEMORY
    add edi, [cursor_pos]
    movzx ebx, byte [current_bg_color]
    mov ah, bl
    mov al, 0x20  ; space
    mov word [edi], ax
    pop ebx
    pop eax
    mov byte [cursor_visible], 1
    ret
.not_bs:
    
    ; Handle enter
    cmp cl, 0x1C
    jne .not_enter
    mov eax, [cursor_pos]
    shr eax, 1
    xor edx, edx
    push ecx
    mov ecx, SCREEN_WIDTH
    div ecx
    inc eax
    cmp eax, SCREEN_HEIGHT
    jl .enter_ok
    mov eax, SCREEN_HEIGHT - 1
.enter_ok:
    mul ecx
    shl eax, 1
    mov [cursor_pos], eax
    pop ecx
    mov byte [cursor_visible], 1
    ret
.not_enter:
    
    ; Handle space
    cmp cl, 0x39
    jne .not_space
    mov al, ' '
    jmp .write_char
.not_space:
    
    ; Map all scancodes directly - Numbers
    cmp cl, 0x02
    jne .not_1
    mov al, '1'
    jmp .write_char
.not_1:
    cmp cl, 0x03
    jne .not_2
    mov al, '2'
    jmp .write_char
.not_2:
    cmp cl, 0x04
    jne .not_3
    mov al, '3'
    jmp .write_char
.not_3:
    cmp cl, 0x05
    jne .not_4
    mov al, '4'
    jmp .write_char
.not_4:
    cmp cl, 0x06
    jne .not_5
    mov al, '5'
    jmp .write_char
.not_5:
    cmp cl, 0x07
    jne .not_6
    mov al, '6'
    jmp .write_char
.not_6:
    cmp cl, 0x08
    jne .not_7
    mov al, '7'
    jmp .write_char
.not_7:
    cmp cl, 0x09
    jne .not_8
    mov al, '8'
    jmp .write_char
.not_8:
    cmp cl, 0x0A
    jne .not_9
    mov al, '9'
    jmp .write_char
.not_9:
    cmp cl, 0x0B
    jne .not_0
    mov al, '0'
    jmp .write_char
.not_0:
    ; Q row
    cmp cl, 0x10
    jne .not_q
    mov al, 'q'
    jmp .write_char
.not_q:
    cmp cl, 0x11
    jne .not_w
    mov al, 'w'
    jmp .write_char
.not_w:
    cmp cl, 0x12
    jne .not_e
    mov al, 'e'
    jmp .write_char
.not_e:
    cmp cl, 0x13
    jne .not_r
    mov al, 'r'
    jmp .write_char
.not_r:
    cmp cl, 0x14
    jne .not_t
    mov al, 't'
    jmp .write_char
.not_t:
    cmp cl, 0x15
    jne .not_y
    mov al, 'y'
    jmp .write_char
.not_y:
    cmp cl, 0x16
    jne .not_u
    mov al, 'u'
    jmp .write_char
.not_u:
    cmp cl, 0x17
    jne .not_i
    mov al, 'i'
    jmp .write_char
.not_i:
    cmp cl, 0x18
    jne .not_o
    mov al, 'o'
    jmp .write_char
.not_o:
    cmp cl, 0x19
    jne .not_p
    mov al, 'p'
    jmp .write_char
.not_p:
    ; A row
    cmp cl, 0x1E
    jne .not_a
    mov al, 'a'
    jmp .write_char
.not_a:
    cmp cl, 0x1F
    jne .not_s
    mov al, 's'
    jmp .write_char
.not_s:
    cmp cl, 0x20
    jne .not_d
    mov al, 'd'
    jmp .write_char
.not_d:
    cmp cl, 0x21
    jne .not_f
    mov al, 'f'
    jmp .write_char
.not_f:
    cmp cl, 0x22
    jne .not_g
    mov al, 'g'
    jmp .write_char
.not_g:
    cmp cl, 0x23
    jne .not_h
    mov al, 'h'
    jmp .write_char
.not_h:
    cmp cl, 0x24
    jne .not_j
    mov al, 'j'
    jmp .write_char
.not_j:
    cmp cl, 0x25
    jne .not_k
    mov al, 'k'
    jmp .write_char
.not_k:
    cmp cl, 0x26
    jne .not_l
    mov al, 'l'
    jmp .write_char
.not_l:
    ; Z row
    cmp cl, 0x2C
    jne .not_z
    mov al, 'z'
    jmp .write_char
.not_z:
    cmp cl, 0x2D
    jne .not_x
    mov al, 'x'
    jmp .write_char
.not_x:
    cmp cl, 0x2E
    jne .not_c
    mov al, 'c'
    jmp .write_char
.not_c:
    cmp cl, 0x2F
    jne .not_v
    mov al, 'v'
    jmp .write_char
.not_v:
    cmp cl, 0x30
    jne .not_b
    mov al, 'b'
    jmp .write_char
.not_b:
    cmp cl, 0x31
    jne .not_n
    mov al, 'n'
    jmp .write_char
.not_n:
    cmp cl, 0x32
    jne .not_m
    mov al, 'm'
    jmp .write_char
.not_m:
    ; Symbols
    cmp cl, 0x33
    jne .not_comma
    mov al, ','
    jmp .write_char
.not_comma:
    cmp cl, 0x34
    jne .not_period
    mov al, '.'
    jmp .write_char
.not_period:
    cmp cl, 0x35
    jne .not_slash
    mov al, '/'
    jmp .write_char
.not_slash:
    
.write_char:
    ; eax has the ASCII character
    ; Write it with current background color
    push ebx
    mov edi, VGA_MEMORY
    add edi, [cursor_pos]
    
    ; Write character byte (low byte)
    mov byte [edi], al
    ; Write color byte (high byte) using current_bg_color
    movzx ebx, byte [current_bg_color]
    mov byte [edi+1], bl
    pop ebx
    
    ; Move cursor
    add dword [cursor_pos], 2
    mov byte [cursor_visible], 1
    
.no_key:
    ret
