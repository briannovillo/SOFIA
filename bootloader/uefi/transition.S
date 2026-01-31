/*
 * SOFIA OS - UEFI to 32-bit Transition Stub
 * Switches from 64-bit long mode to 32-bit protected mode
 * Then jumps to kernel at 0x100000
 */

.code64

.section .text

.global jump_to_kernel_32

// GDT for 32-bit protected mode
.align 16
gdt32:
    .quad 0x0000000000000000    // Null descriptor
    .quad 0x00CF9A000000FFFF    // 32-bit code segment (selector 0x08)
    .quad 0x00CF92000000FFFF    // 32-bit data segment (selector 0x10)
gdt32_end:

gdt32_descriptor:
    .word gdt32_end - gdt32 - 1 // Limit
    .quad gdt32                  // Base

/*
 * jump_to_kernel_32(UINT64 kernel_address)
 * Transitions from 64-bit to 32-bit and jumps to kernel
 * Parameter: RDI = kernel address (0x100000)
 */
jump_to_kernel_32:
    // Save kernel address in EBX (will survive mode switch)
    mov %rdi, %rbx
    
    // Disable interrupts
    cli
    
    // Load our 32-bit GDT (while still in 64-bit)
    lgdt gdt32_descriptor(%rip)
    
    // Jump to 32-bit compatibility mode
    // We need to do a far jump to load CS with the 32-bit code selector
    pushq $0x08                  // Push 32-bit code segment selector
    leaq compatibility_mode(%rip), %rax
    pushq %rax
    lretq                        // Far return (loads CS:RIP)

.code32
compatibility_mode:
    // Now we're in 32-bit compatibility mode
    // Paging is still enabled, but we're in a 32-bit code segment
    
    // Set up all segment registers with 32-bit data selector
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    
    // Now disable paging and long mode
    // First, disable paging (CR0.PG = bit 31)
    mov %cr0, %eax
    and $0x7FFFFFFF, %eax        // Clear bit 31 (PG)
    mov %eax, %cr0
    
    // Disable long mode (IA32_EFER.LME = bit 8)
    mov $0xC0000080, %ecx        // IA32_EFER MSR
    rdmsr
    and $0xFFFFFEFF, %eax        // Clear bit 8 (LME)
    wrmsr
    
    // Set up a basic stack for the kernel
    // Use memory just below 1MB (0x9FC00)
    movl $0x9FC00, %esp
    
    // EBX still has kernel address (0x100000)
    // Jump to kernel - now in pure 32-bit protected mode
    jmp *%ebx
    
    // Should never return
    hlt
    jmp .

.code64
