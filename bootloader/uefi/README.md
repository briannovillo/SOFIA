# SOFIA OS – UEFI Bootloader

## Status

- **Legacy/MBR boot:** Working (e.g. ASUS N56VB).
- **UEFI boot:** Implemented and working (HP All-in-One and modern PCs with UEFI).

## Why UEFI?

Many current machines (e.g. HP All-in-One) only support UEFI and no longer offer Legacy/CSM. Booting from USB then requires a UEFI bootloader and an EFI application.

## UEFI vs Legacy

| Feature      | Legacy/MBR        | UEFI                    |
|-------------|-------------------|-------------------------|
| Boot code   | 512 bytes @ sector 0 | .efi (PE32+) in ESP   |
| Partition   | MBR               | GPT + ESP (FAT32)       |
| File layout | Raw sectors       | /EFI/BOOT/ on FAT32     |
| Kernel      | 32-bit @ 0x100000 | 64-bit @ 2MB (0x200000) |

## UEFI Boot Flow

1. Firmware reads GPT and mounts the EFI System Partition (FAT32).
2. Loads `/EFI/BOOT/BOOTX64.EFI`.
3. UEFI application loads `kernel64.bin` to 2MB.
4. Gets GOP framebuffer (base, pitch, width, height).
5. Allocates kernel stack, then jumps to kernel with:  
   `RDI=fb_base`, `RSI=pitch`, `RDX=width`, `RCX=height`, `R8=bpp`, `R9=kernel_base`.
6. Kernel runs in long mode and draws to GOP (white background, SOFIA logo, cursor).

## Build and Test

**Build UEFI bootloader:**

```bash
cd bootloader/uefi
./build-uefi.sh
```

**Build 64-bit kernel:**

```bash
cd kernel
./build-kernel64.sh
```

**Test under QEMU with UEFI (OVMF):**

```bash
cd bootloader/uefi
./test-uefi-qemu.sh
```

The script builds (if needed), creates an EFI disk image with BOOTX64.EFI and kernel64.bin, and starts QEMU with OVMF.

## Dependencies

- **macOS:** `brew install qemu` (OVMF included).
- **Ubuntu/Debian:** `sudo apt install ovmf qemu-system-x86 mtools dosfstools`
- **Arch:** `sudo pacman -S edk2-ovmf qemu mtools dosfstools`

Docker toolchain: build image from repo root or `toolchain/` (see [toolchain/README.md](../../toolchain/README.md)). Use `DOCKER_CMD="sudo docker"` if your user is not in the `docker` group.

## Current Workaround When UEFI-Only and No CSM

If the machine has no Legacy/CSM option:

1. Use this UEFI bootloader and create a USB with an ESP (FAT32) containing `/EFI/BOOT/BOOTX64.EFI` and the kernel as `kernel64.bin` (or as copied by the test script).
2. Boot in UEFI mode and select the USB from the boot menu.
