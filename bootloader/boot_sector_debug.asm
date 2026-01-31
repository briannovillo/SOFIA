; SOFIA OS - MBR Bootloader with DELAYS for debugging
BITS 16
ORG 0x7C00

start:
    ; Set up segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Save drive number
    mov [boot_drive], dl
    
    ; Clear screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    ; Message 1
    mov si, msg_boot
    call print_string
    call wait_key
    
    ; Read kernel from disk
    mov si, msg_reading
    call print_string
    
    mov ah, 0x02        ; Function: read sectors
    mov al, 32          ; Read 32 sectors (16KB)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2
    mov dh, 0           ; Head 0
    mov dl, [boot_drive]
    mov bx, 0x1000      ; Load at 0x1000:0x0000
    mov es, bx
    xor bx, bx
    int 0x13
    jc disk_error
    
    ; Success
    mov si, msg_loaded
    call print_string
    call wait_key
    
    ; Enable A20
    mov si, msg_a20
    call print_string
    in al, 0x92
    or al, 2
    out 0x92, al
    call wait_key
    
    ; Enter protected mode
    mov si, msg_pmode
    call print_string
    call wait_key
    
    cli
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Jump to 32-bit code
    jmp CODE_SEG:protected_mode

disk_error:
    mov si, msg_error
    call print_string
    call wait_key
    jmp hang

print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

wait_key:
    pusha
    mov si, msg_press
    call print_string
    xor ax, ax
    int 0x16        ; Wait for key
    ; New line
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    popa
    ret

hang:
    hlt
    jmp hang

; Data
boot_drive: db 0
msg_boot:    db '[1] SOFIA Boot started', 13, 10, 0
msg_reading: db '[2] Reading kernel...', 13, 10, 0
msg_loaded:  db '[3] Kernel loaded OK', 13, 10, 0
msg_a20:     db '[4] Enabling A20...', 13, 10, 0
msg_pmode:   db '[5] Entering protected mode...', 13, 10, 0
msg_error:   db '[ERROR] Could not read disk', 13, 10, 0
msg_press:   db ' [Press key]', 0

; GDT
gdt_start:
    dq 0x0000000000000000

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Protected mode (32 bits)
BITS 32
protected_mode:
    ; Set up segments
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    
    ; Write 'PM' (Protected Mode) to VGA
    mov edi, 0xB8000
    mov word [edi], 0x2F50    ; 'P' green
    mov word [edi+2], 0x2F4D  ; 'M' green
    
    ; Copy kernel from 0x10000 to 0x100000
    mov esi, 0x10000
    mov edi, 0x100000
    mov ecx, 4096
    rep movsd
    
    ; Write 'JK' (Jump Kernel) before jumping
    mov edi, 0xB8000
    add edi, 160        ; Second line
    mov word [edi], 0x4F4A    ; 'J' red
    mov word [edi+2], 0x4F4B  ; 'K' red
    
    ; Jump to kernel
    jmp CODE_SEG:0x100000

; Fill to 510 bytes
times 510-($-$$) db 0
dw 0xAA55
