# SOFIA OS

**S.O.F.I.A** = *First AI Operating System*

## 🎉 Operating System Built Entirely by AI

✅ **Boots on real hardware** - tested on:
  * ASUS N56VB Notebook
  * HP 22-dd2031LA All-in-One

✅ **Custom MBR Bootloader** (512 bytes in Assembly)  
✅ **Custom Kernel** (4KB in Assembly)  
✅ **No GRUB, no SYSLINUX, no other OS dependencies**  
✅ **100% code from scratch**

---

## 📺 Demo

### Boot Sequence

When booting from USB you'll see:

```
[1] SOFIA Boot started
[2] Reading kernel...
[3] Kernel loaded OK
[4] Enabling A20...
[5] Entering protected mode...
PM (Protected Mode activated)
```

### Kernel Interface

After successful boot:

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│                         SSSSS  OOO  FFFF III  AAA                          │
│                         S     O   O F     I  A   A                         │
│                         SSSS  O   O FFF   I  AAAAA                         │
│                             S O   O F     I  A   A                         │
│                         SSSSS  OOO  F    III A   A                         │
│                                                                            │
│                                                                            │
│                       First AI Operating System                            │
│                                                                            │
│                                                                            │
│ █ ← Blinking cursor                                                        │
│                                                                            │
│ (Type here - keyboard input works!)                                        │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture

**Two boot paths:**

| Path | Bootloader | Kernel | Display |
|------|------------|--------|---------|
| **Legacy/MBR** | `boot_sector_debug.asm` (512 B) | `kernel.asm` → kernel.bin | VGA text 80×25 |
| **UEFI** | `bootloader/uefi` → BOOTX64.EFI | `kernel64.asm` → kernel64.bin | GOP framebuffer |

### Legacy (MBR)

```
┌─────────────────────────────────────┐
│  MBR Bootloader (512 bytes)         │
│  - boot_sector_debug.asm            │
│  - Loads kernel from sector 2       │
│  - Switches to 32-bit protected mode│
│  - Jumps to 0x100000                │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Kernel (kernel.bin)                │
│  - kernel.asm (modular)             │
│  - VGA text mode UI                  │
│  - Keyboard, speaker, logo          │
└─────────────────────────────────────┘
```

### UEFI (GOP)

```
┌─────────────────────────────────────┐
│  UEFI Bootloader (C + GNU-EFI)      │
│  - bootloader/uefi/ → BOOTX64.EFI   │
│  - Loads kernel64.bin at 2MB        │
│  - Passes GOP: RDI=fb, RSI=pitch,   │
│    RDX=width, RCX=height            │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  64-bit Kernel (kernel64.bin)      │
│  - kernel64.asm (GOP path inline)   │
│  - White screen, SOFIA logo (each   │
│    letter made of many S,O,F,I,A),  │
│  - Blinking cursor (left, below     │
│    logo); slow blink (80M cycles)   │
└─────────────────────────────────────┘
```

---

## 📂 Project Structure

```
SOFIA/
├── .gitignore
├── LICENSE
├── README.md
├── test-qemu.sh                             # QEMU test (Legacy)
│
├── bootloader/
│   ├── boot_sector_debug.asm                # MBR bootloader (Legacy)
│   ├── boot_sector_debug.bin
│   └── uefi/                               # UEFI bootloader
│       ├── bootloader.c
│       ├── build-uefi.sh
│       ├── Makefile
│       ├── README.md
│       ├── test-uefi-qemu.sh                # QEMU + OVMF test
│       └── BOOTX64.EFI
│
├── kernel/
│   ├── build-kernel.sh                      # Legacy kernel
│   ├── build-kernel64.sh                    # 64-bit kernel (UEFI)
│   ├── arch/x86_64/
│   │   ├── kernel.asm                       # Legacy kernel
│   │   ├── kernel64.asm                     # 64-bit kernel (GOP logo, cursor)
│   │   ├── modules/                         # Legacy modules
│   │   └── modules64/                       # 64-bit modules (video, ui, drivers)
│   └── build/
│       ├── kernel.bin
│       └── kernel64.bin
│
├── scripts/
│   └── make-bootable-usb-simple.sh
│
└── toolchain/
    ├── Dockerfile
    └── README.md
```

---

## 🚀 How to Build

### Requirements

- **Docker Desktop** (Windows, macOS or Linux)
- **QEMU** (for testing) - [Install guide](https://www.qemu.org/download/)
- **USB drive** of at least 50MB (only for real hardware testing)

### 1. Build Docker Image

```bash
cd toolchain
docker build --platform linux/amd64 -t sofia-uefi-toolchain .
cd ..
```

### 2. Compile Bootloader

```bash
cd bootloader
docker run --rm --platform linux/amd64 -v "$(pwd)":/work -w /work sofia-uefi-toolchain bash -c "
apt-get update -qq && apt-get install -y -qq nasm
nasm -f bin boot_sector_debug.asm -o boot_sector_debug.bin
"
cd ..
```

### 3. Compile Kernel

**Legacy (VGA):**
```bash
cd kernel
./build-kernel.sh
# → build/kernel.bin
```

**UEFI (64-bit, GOP):**
```bash
cd kernel
./build-kernel64.sh
# → build/kernel64.bin
```

**UEFI bootloader:** build from `bootloader/uefi` (see [bootloader/uefi/README.md](bootloader/uefi/README.md)).

---

## 🧪 Testing with QEMU (Before USB)

**IMPORTANT**: Always test your changes in QEMU before creating a bootable USB. This saves time and prevents wear on USB drives.

### Quick Test Script (Recommended)

```bash
./test-qemu.sh
```

This script will:
- ✅ Check that all binaries are built
- ✅ Create a test image
- ✅ Install bootloader and kernel
- ✅ Launch QEMU automatically

### Manual Testing

If you prefer to do it manually, create a test image and launch QEMU:

```bash
# Create test image (1MB)
dd if=/dev/zero of=sofia_test.img bs=1M count=1

# Install bootloader at sector 0
dd if=bootloader/boot_sector_debug.bin of=sofia_test.img bs=512 count=1 conv=notrunc

# Install kernel at sector 2
dd if=kernel/build/kernel.bin of=sofia_test.img bs=512 seek=2 conv=notrunc

# Launch QEMU
qemu-system-x86_64 \
  -drive file=sofia_test.img,format=raw \
  -m 128M \
  -vga std
```

### What You Should See

If everything works correctly:
1. ✅ Bootloader messages (SOFIA Boot started, Reading kernel, etc.)
2. ✅ White/gray background screen
3. ✅ SOFIA logo (large ASCII art letters)
4. ✅ Subtitle: "First AI Operating System"
5. ✅ Blinking cursor (Commodore 64 style)
6. ✅ Keyboard input working (type letters, numbers)
7. ✅ TAB key changes entire screen background color (4 themes available)
8. ✅ Startup beep (may not work in all QEMU versions)

### Testing Checklist

Before creating a USB, verify in QEMU:

- [ ] System boots without errors
- [ ] Logo displays correctly
- [ ] Cursor blinks at correct speed
- [ ] Keyboard input works (try typing: `hello world 123`)
- [ ] Backspace works
- [ ] Enter key moves to next line
- [ ] Space bar works
- [ ] TAB key cycles background colors (white/gray → cyan → yellow → beige → repeat)

### Common QEMU Issues

| Problem | Solution |
|---------|----------|
| **Black screen** | Check that kernel.bin exists and is 4KB |
| **"No bootable device"** | Bootloader not at sector 0, check dd command |
| **Garbled text** | Wrong VGA mode or kernel compiled as ELF (must be flat binary) |
| **No keyboard input** | Make sure QEMU window has focus |
| **No sound** | Normal - QEMU often doesn't emulate PC speaker correctly |

### Testing UEFI (GOP) in QEMU

Build the 64-bit kernel and UEFI bootloader, then run:

```bash
cd bootloader/uefi
./test-uefi-qemu.sh
```

You should see a white screen, the SOFIA logo (letters made of letters), and a slow-blinking cursor on the left below the logo. See [bootloader/uefi/README.md](bootloader/uefi/README.md) for dependencies (OVMF, mtools, etc.).

### QEMU Keyboard Shortcuts

- **Ctrl+Alt+G** - Release mouse from QEMU window
- **Ctrl+Alt+F** - Toggle fullscreen
- **Ctrl+Alt+2** - Switch to QEMU monitor (for debugging)
- **Ctrl+Alt+1** - Switch back to console

### Color Themes

Press **TAB** to cycle through 4 light background colors:

| Theme | Background Color | Visual Style |
|-------|-----------------|--------------|
| **Default** | White/Gray (0x70) | Clean, classic look |
| **Cyan** | Light Cyan (0xB0) | Cool, modern blue-white |
| **Yellow** | Pastel Yellow (0xE0) | Warm, high-visibility |
| **Beige** | Cream/Brown (0x60) | Retro, paper-like |

**Note**: All themes use black text (0x0) for optimal readability. Dark backgrounds are intentionally excluded to ensure text visibility.

---

## 💾 Create Bootable USB (After QEMU Testing)

### macOS

```bash
# 1. List USB devices
diskutil list | grep -A3 "external"

# 2. Run script (replace disk4 with your device)
./scripts/make-bootable-usb-simple.sh /dev/disk4

# 3. Run manually (requires password):
sudo dd if=bootloader/boot_sector_debug.bin of=/dev/disk4 bs=512 count=1
sudo dd if=kernel/build/kernel.bin of=/dev/disk4 bs=512 seek=2 conv=notrunc
sync
diskutil eject /dev/disk4
```

### Linux

```bash
# 1. List USB devices
lsblk

# 2. Unmount if mounted (replace sdb with your device)
sudo umount /dev/sdb*

# 3. Create MBR/FAT32 partition
sudo fdisk /dev/sdb
# (d to delete partitions, n for new, t for type b (FAT32), w to write)

sudo mkfs.vfat -F 32 /dev/sdb1

# 4. Install boot sector and kernel
sudo dd if=bootloader/boot_sector_debug.bin of=/dev/sdb bs=512 count=1
sudo dd if=kernel/build/kernel.bin of=/dev/sdb bs=512 seek=2 conv=notrunc
sync
```

### Windows

Use [Rufus](https://rufus.ie/) in DD mode or run in PowerShell (as administrator):

```powershell
# 1. List devices
wmic diskdrive list brief

# 2. Write with dd (requires dd for Windows)
dd if=bootloader/boot_sector_debug.bin of=\\.\PhysicalDrive1 bs=512 count=1
dd if=kernel/build/kernel.bin of=\\.\PhysicalDrive1 bs=512 seek=2
```

---

## 🖥️ Booting on Real Hardware

### BIOS/UEFI Configuration (IMPORTANT)

1. **Restart** and press **F2**, **F10** or other key to enter BIOS
2. **Boot tab:**
   - **Boot Mode** = **Legacy** (NOT UEFI) ✅
   - **Launch CSM** = **ENABLED** ✅
3. **Security tab:**
   - **Secure Boot** = **DISABLED** ✅
4. **F10** to save and restart
5. **ESC** or **F8** for Boot Menu
6. Select the USB (should appear as "USB HDD", **WITHOUT** "UEFI:" prefix)

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| **BIOS doesn't detect USB** | Make sure to create MBR partition (not just copy image) |
| **Restarts immediately** | Switch to Legacy Boot (disable UEFI) |
| **Black screen** | Disable Secure Boot and Fast Boot |
| **Only see "PM"** | Kernel is ELF instead of flat binary - use `nasm -f bin` |
| **Weird colors** | Same problem - use flat binary |

---

## 📚 Current Features

**Legacy boot:**  
✅ Custom MBR bootloader (512 bytes, Assembly)  
✅ Modular kernel, VGA text 80×25, software cursor, TAB color themes  
✅ PS/2 keyboard, PC speaker beep  
✅ SOFIA logo (each letter made of itself), subtitle "First AI Operating System"

**UEFI boot:**  
✅ UEFI bootloader (GNU-EFI), loads 64-bit kernel at 2MB  
✅ GOP framebuffer: white background, SOFIA logo (letters made of letters: S from many S’s, O from O’s, etc.), 464×80 px, centered  
✅ Blinking cursor left below logo, slow blink (80M cycles)  
✅ Same toolchain (Docker) for both builds  

## 📚 Next Steps

### Level 1: More kernel functionality
- [ ] Handle interrupts (IDT)
- [ ] Hardware interrupts for keyboard (IRQ1)
- [x] 64-bit mode (long mode) – UEFI kernel
- [ ] Command interpreter / shell

### Level 2: File system
- [ ] Read files from USB (FAT32)
- [ ] Load programs from files
- [ ] Basic file operations

### Level 3: Multitasking
- [ ] Basic scheduler
- [ ] Context switching
- [ ] Processes
- [ ] IPC (Inter-Process Communication)

### Level 4: Drivers
- [ ] Network driver (E1000)
- [ ] Disk driver (ATA/AHCI)
- [x] Graphics (GOP framebuffer – UEFI path)
- [ ] USB driver

---

## 👥 Contributing

### Development Workflow

1. **Make changes** to the code (bootloader or kernel modules)

2. **Build** your changes:
   ```bash
   # Build bootloader
   cd bootloader
   docker run --rm --platform linux/amd64 -v "$(pwd)":/work -w /work sofia-uefi-toolchain bash -c "
   apt-get update -qq && apt-get install -y -qq nasm
   nasm -f bin boot_sector_debug.asm -o boot_sector_debug.bin
   "
   
   # Build kernel
   cd ../kernel
   ./build-kernel.sh
   ```

3. **Test in QEMU** (ALWAYS before USB):
   ```bash
   cd ..
   ./test-qemu.sh
   ```

4. **If tests pass**, create bootable USB for real hardware testing

5. **If tests fail**, fix issues and go back to step 2

### Modifying the Kernel

The kernel is organized in modules at `kernel/arch/x86_64/modules/`:

- **`video/`** - VGA operations and cursor rendering
- **`ui/`** - Logo and interface elements  
- **`drivers/`** - Keyboard, speaker, and hardware drivers

To add a new module:
1. Create `modules/category/mymodule.asm`
2. Add `%include "modules/category/mymodule.asm"` in `kernel.asm`
3. Build and test with QEMU
4. See `kernel/arch/x86_64/modules/README.md` for details

### Reporting Issues

When reporting issues, please include:
- Operating system and version
- QEMU version (if testing in emulator)
- Hardware specs (if testing on real hardware)
- Steps to reproduce
- Screenshot or photo of the issue

---

## 📄 License

MIT (see LICENSE)
