# SOFIA OS - Kernel Modules

This folder contains the kernel modules organized by functionality.

## Module Structure

```
modules/
├── video/              # Video and display
│   ├── vga.asm        # VGA text mode operations
│   └── cursor.asm     # Software cursor rendering
├── ui/                 # User interface
│   └── logo.asm       # SOFIA logo and subtitle
└── drivers/            # Hardware drivers
    ├── keyboard.asm   # PS/2 keyboard driver
    └── speaker.asm    # PC speaker sound generation
```

## Modules Overview

### Video (`modules/video/`)
- **vga.asm**: Basic VGA operations
  - `disable_cursor`: Disables hardware VGA cursor
- **cursor.asm**: Software cursor rendering
  - `draw_cursor`: Draws software cursor (█)
  - `erase_cursor`: Erases cursor (space)

### UI (`modules/ui/`)
- **logo.asm**: SOFIA branding and interface
  - `draw_sofia_large`: Draws SOFIA logo (each letter made of itself)
  - `draw_subtitle`: Draws "First AI Operating System"

### Drivers (`modules/drivers/`)
- **keyboard.asm**: PS/2 keyboard driver with complete scancode to ASCII mapping
  - `check_keyboard`: Reads and processes keyboard input
  - Hardcoded scancode mapping
  - Special keys handling (Enter, Backspace, Space)
  - Full support for: A-Z, 0-9, and basic symbols
- **speaker.asm**: PC speaker sound generation
  - `beep`: Generates startup beep using PC speaker

## Kernel Structure

```
kernel/
├── build/                    # Compiled binaries
│   └── kernel.bin
├── arch/x86_64/              # x86_64 architecture
│   ├── kernel.asm            # ⭐ Main kernel (includes all modules)
│   └── modules/              # Kernel modules
│       ├── video/            # Video and display
│       ├── ui/               # User interface
│       └── drivers/          # Hardware drivers
└── build-kernel.sh           # Build script
```

## Main File: `kernel.asm`

The main kernel file that:
- Defines global constants (VGA_MEMORY, SCREEN_WIDTH, etc.)
- Contains entry point `start`
- Includes all modules using `%include`
- Defines main loop
- Declares global variables (cursor_pos, cursor_visible)

## Execution Flow

1. **Startup** (`start`)
   - Clears VGA screen (white background)
   - Disables hardware cursor
   - Plays startup beep
   - Draws logo and subtitle
   - Initializes cursor position

2. **Main Loop** (`main_loop`)
   - Draws/erases cursor based on visibility
   - Checks keyboard 4000 times with small delays
   - Toggles cursor visibility
   - Repeats infinitely

## Building

### Method 1: Script (Recommended)
```bash
cd kernel
./build-kernel.sh
```

### Method 2: Manual
```bash
cd kernel/arch/x86_64
nasm -f bin kernel.asm -o ../../build/kernel.bin
```

### Create Bootable Image
```bash
dd if=/dev/zero of=sofia_test.img bs=1M count=1
dd if=bootloader/boot_sector_debug.bin of=sofia_test.img bs=512 count=1 conv=notrunc
dd if=kernel/build/kernel.bin of=sofia_test.img bs=512 seek=2 conv=notrunc
```

## Adding New Modules

1. **Create module file**
   ```bash
   touch kernel/arch/x86_64/modules/category/name.asm
   ```

2. **Write module code**
   ```assembly
   ; Example module
   my_function:
       ; code here
       ret
   ```

3. **Include in kernel.asm**
   ```assembly
   %include "modules/category/name.asm"
   ```

4. **Rebuild**
   ```bash
   ./build-kernel.sh
   ```

## Modular Architecture Benefits

✅ **Organization**: Code separated by functionality  
✅ **Maintainability**: Easy to find and edit specific code  
✅ **Scalability**: Simple to add new functionality  
✅ **Clarity**: Each module has a single responsibility  
✅ **Reusability**: Modules can be used in other projects  

## Global Variables

- `cursor_pos`: Current cursor position (offset in VGA memory)
- `cursor_visible`: Cursor state (1 = visible, 0 = hidden)

## Constants

- `VGA_MEMORY`: 0xB8000 (VGA memory address)
- `SCREEN_WIDTH`: 80 characters
- `SCREEN_HEIGHT`: 25 lines

## Code Statistics

```
keyboard.asm  296 lines  40.2%  (PS/2 driver + scancode mapping)
logo.asm      277 lines  37.6%  (SOFIA logo rendering)
kernel.asm     95 lines  12.9%  (Main orchestrator)
speaker.asm    32 lines   4.3%  (PC speaker beep)
cursor.asm     24 lines   3.3%  (Cursor rendering)
vga.asm        12 lines   1.6%  (VGA operations)
─────────────────────────────────
Total         736 lines  100%
```
