; PC Speaker Module - 64-bit version
; Sound generation using PC speaker

; Play startup beep using PC speaker
beep:
    push rax
    push rcx
    
    ; Set up PIT channel 2 for tone generation (1000 Hz - higher pitch)
    mov al, 0xB6
    out 0x43, al
    mov ax, 1193    ; Divisor for ~1000 Hz (higher = more audible)
    out 0x42, al
    mov al, ah
    out 0x42, al
    
    ; Turn on speaker
    in al, 0x61
    or al, 3
    out 0x61, al
    
    ; Short delay (long delay can feel like hang; I/O may be slow in UEFI)
    mov rcx, 500000
.beep_delay:
    nop
    loop .beep_delay
    
    ; Turn off speaker
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    
    pop rcx
    pop rax
    ret
