/* Minimal stub in .text: write 'K' to 0xB8000 and halt. For testing jump + VGA. */
.code64
.section .text
.global minimal_stub
minimal_stub:
    movabs $0xB8000, %rax
    movw   $0x074B, (%rax)   /* 'K' (0x4B) attr 0x07; VGA: low=char, high=attr */
    hlt
    jmp    .
