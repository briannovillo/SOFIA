/*
 * SOFIA OS - UEFI Bootloader
 * Loads kernel and switches to 32-bit protected mode
 */

#include <efi.h>
#include <efilib.h>

#define KERNEL_LOAD_ADDRESS 0x200000  // 2MB - OVMF often reserves 1MB; try 2MB so kernel runs
#define BOOT_INFO_ADDR      0x8000    /* Boot info for kernel: GOP framebuffer etc. */
#define BOOT_INFO_MAGIC     0x534F4649u  /* "SOFI" */
/* Boot info layout: +0x00 magic, +0x04 fb_base(8), +0x0C pitch, +0x10 width, +0x14 height, +0x18 bpp, +0x1C kernel_base(8) */
#define BOOT_INFO_KERNEL_BASE 0x1C

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    EFI_STATUS Status;
    EFI_LOADED_IMAGE *LoadedImage;
    EFI_FILE_IO_INTERFACE *FileSystem;
    EFI_FILE *Root;
    EFI_FILE *KernelFile;
    UINTN KernelSize;
    
    // Initialize GNU-EFI library
    InitializeLib(ImageHandle, SystemTable);
    
    // Clear screen and print banner
    uefi_call_wrapper(SystemTable->ConOut->ClearScreen, 1, SystemTable->ConOut);
    Print(L"\n");
    Print(L"========================================\n");
    Print(L"  SOFIA OS - UEFI Bootloader v0.2\n");
    Print(L"  First AI Operating System\n");
    Print(L"========================================\n\n");
    
    Print(L"[1] Loading kernel from EFI partition...\n");
    
    // Get loaded image protocol
    Status = uefi_call_wrapper(SystemTable->BootServices->HandleProtocol, 3,
                               ImageHandle,
                               &LoadedImageProtocol,
                               (VOID**)&LoadedImage);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to get LoadedImageProtocol (0x%x)\n", Status);
        return Status;
    }
    
    // Get file system protocol
    Status = uefi_call_wrapper(SystemTable->BootServices->HandleProtocol, 3,
                               LoadedImage->DeviceHandle,
                               &FileSystemProtocol,
                               (VOID**)&FileSystem);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to get FileSystemProtocol (0x%x)\n", Status);
        return Status;
    }
    
    // Open root directory
    Status = uefi_call_wrapper(FileSystem->OpenVolume, 2, FileSystem, &Root);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to open root directory (0x%x)\n", Status);
        return Status;
    }
    
    Print(L"[2] Opening kernel.bin...\n");
    
    // First, navigate to EFI/BOOT directory
    EFI_FILE *EfiDir;
    Status = uefi_call_wrapper(Root->Open, 5,
                               Root,
                               &EfiDir,
                               L"EFI",
                               EFI_FILE_MODE_READ,
                               0);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to open EFI directory (0x%x)\n", Status);
        return Status;
    }
    
    EFI_FILE *BootDir;
    Status = uefi_call_wrapper(EfiDir->Open, 5,
                               EfiDir,
                               &BootDir,
                               L"BOOT",
                               EFI_FILE_MODE_READ,
                               0);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to open BOOT directory (0x%x)\n", Status);
        uefi_call_wrapper(EfiDir->Close, 1, EfiDir);
        return Status;
    }
    
    // Now open kernel64.bin from BOOT directory (64-bit UEFI kernel)
    Status = uefi_call_wrapper(BootDir->Open, 5,
                               BootDir,
                               &KernelFile,
                               L"kernel64.bin",
                               EFI_FILE_MODE_READ,
                               0);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to open kernel64.bin (0x%x)\n", Status);
        Print(L"       Make sure kernel64.bin is in /EFI/BOOT/ directory\n");
        uefi_call_wrapper(BootDir->Close, 1, BootDir);
        uefi_call_wrapper(EfiDir->Close, 1, EfiDir);
        return Status;
    }
    
    // Close directory handles (we have the file handle now)
    uefi_call_wrapper(BootDir->Close, 1, BootDir);
    uefi_call_wrapper(EfiDir->Close, 1, EfiDir);
    
    // Get file size
    EFI_FILE_INFO *FileInfo;
    UINTN FileInfoSize = sizeof(EFI_FILE_INFO) + 256;
    
    Status = uefi_call_wrapper(SystemTable->BootServices->AllocatePool, 3,
                               EfiLoaderData,
                               FileInfoSize,
                               (VOID**)&FileInfo);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to allocate memory for file info (0x%x)\n", Status);
        return Status;
    }
    
    Status = uefi_call_wrapper(KernelFile->GetInfo, 4,
                               KernelFile,
                               &GenericFileInfo,
                               &FileInfoSize,
                               FileInfo);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to get file info (0x%x)\n", Status);
        return Status;
    }
    
    KernelSize = FileInfo->FileSize;
    Print(L"[3] Kernel size: %d bytes\n", KernelSize);
    
    uefi_call_wrapper(SystemTable->BootServices->FreePool, 1, FileInfo);
    
    // Allocate at 2MB (must match kernel org 0x200000). OVMF often reserves 1MB.
    UINTN Pages = (KernelSize + 4095) / 4096;
    EFI_PHYSICAL_ADDRESS KernelAddress = KERNEL_LOAD_ADDRESS;
    
    Status = uefi_call_wrapper(SystemTable->BootServices->AllocatePages, 4,
                               AllocateAddress,
                               EfiLoaderData,
                               Pages,
                               &KernelAddress);
    if (EFI_ERROR(Status)) {
        Print(L"[4] 0x%x unavailable (0x%x), allocating any...\n", KERNEL_LOAD_ADDRESS, Status);
        KernelAddress = 0;
        Status = uefi_call_wrapper(SystemTable->BootServices->AllocatePages, 4,
                                   AllocateAnyPages,
                                   EfiLoaderData,
                                   Pages,
                                   &KernelAddress);
        if (EFI_ERROR(Status)) {
            Print(L"ERROR: Failed to allocate kernel memory (0x%x)\n", Status);
            return Status;
        }
        Print(L"[4] Kernel at 0x%lx (relocated - may hang)\n", (unsigned long)KernelAddress);
    } else {
        Print(L"[4] Loading kernel to 0x%lx...\n", (unsigned long)KernelAddress);
    }
    
    // Read kernel into memory
    Status = uefi_call_wrapper(KernelFile->Read, 3,
                               KernelFile,
                               &KernelSize,
                               (VOID*)(UINTN)KernelAddress);
    if (EFI_ERROR(Status)) {
        Print(L"ERROR: Failed to read kernel (0x%x)\n", Status);
        return Status;
    }
    
    Print(L"[5] Kernel loaded successfully!\n");
    
    // Close file
    uefi_call_wrapper(KernelFile->Close, 1, KernelFile);
    uefi_call_wrapper(Root->Close, 1, Root);
    
    /* Get GOP framebuffer and write boot info at BOOT_INFO_ADDR for kernel */
    *(volatile UINT32 *)BOOT_INFO_ADDR = 0;  /* no GOP by default */
    *(volatile UINT64 *)(BOOT_INFO_ADDR + BOOT_INFO_KERNEL_BASE) = (UINT64)KernelAddress;  /* kernel load address for PIC */
    EFI_GRAPHICS_OUTPUT_PROTOCOL *Gop = NULL;
    Status = uefi_call_wrapper(SystemTable->BootServices->LocateProtocol, 3,
                               &gEfiGraphicsOutputProtocolGuid, NULL, (VOID **)&Gop);
    if (!EFI_ERROR(Status) && Gop != NULL && Gop->Mode != NULL && Gop->Mode->Info != NULL) {
        EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *Info = Gop->Mode->Info;
        UINTN FbBase = (UINTN)Gop->Mode->FrameBufferBase;
        UINT32 Pitch = (UINT32)(Info->PixelsPerScanLine * 4);  /* assume 32bpp */
        UINT32 W = (UINT32)Info->HorizontalResolution;
        UINT32 H = (UINT32)Info->VerticalResolution;
        UINT32 Bpp = 32;
        *(volatile UINT32 *)(BOOT_INFO_ADDR + 0x00) = BOOT_INFO_MAGIC;
        *(volatile UINT64 *)(BOOT_INFO_ADDR + 0x04) = (UINT64)FbBase;
        *(volatile UINT32 *)(BOOT_INFO_ADDR + 0x0C) = Pitch;
        *(volatile UINT32 *)(BOOT_INFO_ADDR + 0x10) = W;
        *(volatile UINT32 *)(BOOT_INFO_ADDR + 0x14) = H;
        *(volatile UINT32 *)(BOOT_INFO_ADDR + 0x18) = Bpp;
        Print(L"[5a] GOP: %ux%u, fb 0x%lx\n", (unsigned)W, (unsigned)H, (unsigned long)FbBase);
    } else {
        Print(L"[5a] No GOP, kernel will use VGA 0xB8000 if available\n");
    }
    
    /* Allocate kernel stack (64KB) so kernel has a valid stack; UEFI stack may be invalid after JMP */
    EFI_PHYSICAL_ADDRESS StackBase = 0;
    UINTN StackPages = 16;  /* 64 KB */
    Status = uefi_call_wrapper(SystemTable->BootServices->AllocatePages, 4,
                               AllocateAnyPages,
                               EfiLoaderData,
                               StackPages,
                               &StackBase);
    UINTN StackTop = (Status == 0) ? (StackBase + (StackPages << 12)) : 0;
    if (StackTop == 0)
        Print(L"[5b] No kernel stack allocated, using current RSP\n");

    Print(L"[6] Jumping to kernel at 0x%lx...\n", (unsigned long)KernelAddress);
    /* RSP = kernel stack top (if allocated), RDI=fb, RSI=pitch, RDX=width, RCX=height, R8=bpp, R9=kernel_base */
    UINTN FbBase = 0;
    UINT32 Pitch = 0, W = 0, H = 0, Bpp = 32;
    if (Gop != NULL && Gop->Mode != NULL && Gop->Mode->Info != NULL) {
        FbBase = (UINTN)Gop->Mode->FrameBufferBase;
        Pitch = (UINT32)(Gop->Mode->Info->PixelsPerScanLine * 4);
        W = (UINT32)Gop->Mode->Info->HorizontalResolution;
        H = (UINT32)Gop->Mode->Info->VerticalResolution;
    }
    __asm__ volatile (
        "test %6, %6\n\t"                 /* StackTop == 0? */
        "jz 0f\n\t"
        "mov %6, %%rsp\n\t"               /* RSP = kernel stack top */
        "and $0xFFFFFFFFFFFFFFF0, %%rsp\n\t"
        "0: and $0xFFFFFFFFFFFFFFF0, %%rsp\n\t"
        "mov %1, %%rdi\n\t"
        "movl %2, %%esi\n\t"
        "movl %3, %%edx\n\t"
        "movl %4, %%ecx\n\t"
        "movl %5, %%r8d\n\t"
        "mov %0, %%r9\n\t"
        "jmp *%0"
        : : "r" ((UINTN)KernelAddress), "r" (FbBase), "r" (Pitch),
          "r" (W), "r" (H), "r" (Bpp), "r" (StackTop)
        : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "memory");
    __builtin_unreachable();
}
