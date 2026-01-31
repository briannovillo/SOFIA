; Logo Module
; SOFIA logo and subtitle rendering

; Draw large SOFIA - each letter made from the letter itself
draw_sofia_large:
    ; S (5x5) - starting at row 4, col 25 (centered)
    ; Row 1: SSSSS
    mov edi, VGA_MEMORY
    add edi, (4 * SCREEN_WIDTH + 25) * 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    
    ; Row 2: S
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 25) * 2
    mov word [edi], 0x7053
    
    ; Row 3: SSSS
    mov edi, VGA_MEMORY
    add edi, (6 * SCREEN_WIDTH + 25) * 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    
    ; Row 4: ....S
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 29) * 2
    mov word [edi], 0x7053
    
    ; Row 5: SSSSS
    mov edi, VGA_MEMORY
    add edi, (8 * SCREEN_WIDTH + 25) * 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    add edi, 2
    mov word [edi], 0x7053
    
    ; O (5x5) - col 32
    ; Row 1: .OOO.
    mov edi, VGA_MEMORY
    add edi, (4 * SCREEN_WIDTH + 33) * 2
    mov word [edi], 0x704F
    add edi, 2
    mov word [edi], 0x704F
    add edi, 2
    mov word [edi], 0x704F
    
    ; Row 2: O...O
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 32) * 2
    mov word [edi], 0x704F
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 36) * 2
    mov word [edi], 0x704F
    
    ; Row 3: O...O
    mov edi, VGA_MEMORY
    add edi, (6 * SCREEN_WIDTH + 32) * 2
    mov word [edi], 0x704F
    mov edi, VGA_MEMORY
    add edi, (6 * SCREEN_WIDTH + 36) * 2
    mov word [edi], 0x704F
    
    ; Row 4: O...O
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 32) * 2
    mov word [edi], 0x704F
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 36) * 2
    mov word [edi], 0x704F
    
    ; Row 5: .OOO.
    mov edi, VGA_MEMORY
    add edi, (8 * SCREEN_WIDTH + 33) * 2
    mov word [edi], 0x704F
    add edi, 2
    mov word [edi], 0x704F
    add edi, 2
    mov word [edi], 0x704F
    
    ; F (5x5) - col 39
    ; Row 1: FFFFF
    mov edi, VGA_MEMORY
    add edi, (4 * SCREEN_WIDTH + 39) * 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    
    ; Row 2: F
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 39) * 2
    mov word [edi], 0x7046
    
    ; Row 3: FFFF
    mov edi, VGA_MEMORY
    add edi, (6 * SCREEN_WIDTH + 39) * 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    add edi, 2
    mov word [edi], 0x7046
    
    ; Row 4: F
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 39) * 2
    mov word [edi], 0x7046
    
    ; Row 5: F
    mov edi, VGA_MEMORY
    add edi, (8 * SCREEN_WIDTH + 39) * 2
    mov word [edi], 0x7046
    
    ; I (5x5) - col 46
    ; Row 1: III
    mov edi, VGA_MEMORY
    add edi, (4 * SCREEN_WIDTH + 46) * 2
    mov word [edi], 0x7049
    add edi, 2
    mov word [edi], 0x7049
    add edi, 2
    mov word [edi], 0x7049
    
    ; Row 2: .I.
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 47) * 2
    mov word [edi], 0x7049
    
    ; Row 3: .I.
    mov edi, VGA_MEMORY
    add edi, (6 * SCREEN_WIDTH + 47) * 2
    mov word [edi], 0x7049
    
    ; Row 4: .I.
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 47) * 2
    mov word [edi], 0x7049
    
    ; Row 5: III
    mov edi, VGA_MEMORY
    add edi, (8 * SCREEN_WIDTH + 46) * 2
    mov word [edi], 0x7049
    add edi, 2
    mov word [edi], 0x7049
    add edi, 2
    mov word [edi], 0x7049
    
    ; A (5x5) - col 51
    ; Row 1: .AAA.
    mov edi, VGA_MEMORY
    add edi, (4 * SCREEN_WIDTH + 52) * 2
    mov word [edi], 0x7041
    add edi, 2
    mov word [edi], 0x7041
    add edi, 2
    mov word [edi], 0x7041
    
    ; Row 2: A...A
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 51) * 2
    mov word [edi], 0x7041
    mov edi, VGA_MEMORY
    add edi, (5 * SCREEN_WIDTH + 55) * 2
    mov word [edi], 0x7041
    
    ; Row 3: AAAAA
    mov edi, VGA_MEMORY
    add edi, (6 * SCREEN_WIDTH + 51) * 2
    mov word [edi], 0x7041
    add edi, 2
    mov word [edi], 0x7041
    add edi, 2
    mov word [edi], 0x7041
    add edi, 2
    mov word [edi], 0x7041
    add edi, 2
    mov word [edi], 0x7041
    
    ; Row 4: A...A
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 51) * 2
    mov word [edi], 0x7041
    mov edi, VGA_MEMORY
    add edi, (7 * SCREEN_WIDTH + 55) * 2
    mov word [edi], 0x7041
    
    ; Row 5: A...A
    mov edi, VGA_MEMORY
    add edi, (8 * SCREEN_WIDTH + 51) * 2
    mov word [edi], 0x7041
    mov edi, VGA_MEMORY
    add edi, (8 * SCREEN_WIDTH + 55) * 2
    mov word [edi], 0x7041
    
    ret

; Draw subtitle (line 11, centered)
draw_subtitle:
    ; Position: line 11, col 27
    mov edi, VGA_MEMORY
    add edi, (11 * SCREEN_WIDTH + 27) * 2
    
    ; Write "First AI Operating System"
    mov word [edi], 0x7046      ; F
    add edi, 2
    mov word [edi], 0x7069      ; i
    add edi, 2
    mov word [edi], 0x7072      ; r
    add edi, 2
    mov word [edi], 0x7073      ; s
    add edi, 2
    mov word [edi], 0x7074      ; t
    add edi, 2
    mov word [edi], 0x7020      ; (space)
    add edi, 2
    mov word [edi], 0x7041      ; A
    add edi, 2
    mov word [edi], 0x7049      ; I
    add edi, 2
    mov word [edi], 0x7020      ; (space)
    add edi, 2
    mov word [edi], 0x704F      ; O
    add edi, 2
    mov word [edi], 0x7070      ; p
    add edi, 2
    mov word [edi], 0x7065      ; e
    add edi, 2
    mov word [edi], 0x7072      ; r
    add edi, 2
    mov word [edi], 0x7061      ; a
    add edi, 2
    mov word [edi], 0x7074      ; t
    add edi, 2
    mov word [edi], 0x7069      ; i
    add edi, 2
    mov word [edi], 0x706E      ; n
    add edi, 2
    mov word [edi], 0x7067      ; g
    add edi, 2
    mov word [edi], 0x7020      ; (space)
    add edi, 2
    mov word [edi], 0x7053      ; S
    add edi, 2
    mov word [edi], 0x7079      ; y
    add edi, 2
    mov word [edi], 0x7073      ; s
    add edi, 2
    mov word [edi], 0x7074      ; t
    add edi, 2
    mov word [edi], 0x7065      ; e
    add edi, 2
    mov word [edi], 0x706D      ; m
    
    ret
