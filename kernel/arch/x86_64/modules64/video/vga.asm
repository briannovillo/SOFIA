; VGA Video Module - 64-bit version
; Basic VGA text mode operations

; Disable text blinking (enable high intensity backgrounds)
; On real hardware, bit 7 of attribute byte can cause blinking
; This function disables blinking mode by setting bit 3 in Mode Control Register
disable_blinking:
    push rax
    push rdx
    
    ; Read Input Status Register #1 to reset the flip-flop
    mov dx, 0x3DA
    in al, dx
    
    ; Write to Attribute Controller Address Register
    ; Index 0x10 (0x30 with bit 5 set) = Mode Control Register
    mov dx, 0x3C0
    mov al, 0x30
    out dx, al
    
    ; Read current value from Attribute Controller Data Register
    inc dx              ; 0x3C1
    in al, dx
    
    ; Set bit 3 = Enable high intensity backgrounds (disable blink)
    or al, 0x08
    
    ; Write back the modified value
    dec dx              ; 0x3C0
    out dx, al
    
    ; Reset flip-flop again
    mov dx, 0x3DA
    in al, dx
    
    ; Re-enable video by writing to Address register with bit 5 set
    mov dx, 0x3C0
    mov al, 0x20
    out dx, al
    
    pop rdx
    pop rax
    ret

; Disable hardware VGA cursor completely (for real hardware)
disable_cursor:
    push rax
    push rdx
    
    ; Disable cursor by setting bit 5 in cursor start register
    mov dx, 0x3D4
    mov al, 0x0A        ; Cursor start register
    out dx, al
    inc dx
    mov al, 0x20        ; Bit 5 = disable cursor
    out dx, al
    
    ; Also set cursor end register
    dec dx
    mov al, 0x0B        ; Cursor end register
    out dx, al
    inc dx
    mov al, 0x20        ; Disable
    out dx, al
    
    ; Move cursor off-screen (to position 2000, beyond 80x25=2000)
    dec dx
    mov al, 0x0E        ; Cursor location high byte
    out dx, al
    inc dx
    mov al, 0x07        ; High byte of 2000
    out dx, al
    
    dec dx
    mov al, 0x0F        ; Cursor location low byte
    out dx, al
    inc dx
    mov al, 0xD0        ; Low byte of 2000
    out dx, al
    
    pop rdx
    pop rax
    ret
