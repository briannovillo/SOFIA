#!/bin/bash
# SOFIA OS - UEFI Testing Script with QEMU + OVMF

set -e

echo "🧪 SOFIA OS - UEFI Boot Test with QEMU"
echo "========================================"
echo ""

# Check if BOOTX64.EFI exists
if [ ! -f "BOOTX64.EFI" ]; then
    echo "❌ BOOTX64.EFI not found!"
    echo "   Run ./build-uefi.sh first"
    exit 1
fi

# Check if 64-bit kernel exists
if [ ! -f "../../kernel/build/kernel64.bin" ]; then
    echo "❌ kernel64.bin not found!"
    echo "   Build 64-bit kernel first: cd ../../kernel && ./build-kernel64.sh"
    exit 1
fi

echo "✅ BOOTX64.EFI found"
echo "✅ kernel64.bin found"
echo ""

# Check if OVMF firmware is available (macOS + Linux paths)
OVMF_PATHS=(
    "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
    "/usr/share/qemu/OVMF.fd"
    "/usr/share/qemu/edk2-x86_64-code.fd"
    "/usr/share/edk2/ovmf/OVMF_CODE.fd"
    "/usr/share/edk2/ovmf/x64/OVMF_CODE.fd"
    "/usr/share/OVMF/OVMF_CODE.fd"
)

OVMF_PATH=""
for path in "${OVMF_PATHS[@]}"; do
    if [ -f "$path" ]; then
        OVMF_PATH="$path"
        break
    fi
done

if [ -z "$OVMF_PATH" ]; then
    echo "❌ OVMF firmware not found!"
    echo ""
    echo "On macOS, install with:"
    echo "  brew install qemu"
    echo ""
    echo "On Ubuntu/Debian:"
    echo "  sudo apt install ovmf qemu-system-x86"
    echo ""
    echo "On Arch Linux:"
    echo "  sudo pacman -S edk2-ovmf qemu"
    exit 1
fi

echo "✅ OVMF firmware found: $OVMF_PATH"

# OVMF_VARS (NVRAM writable) - required so ExitBootServices() doesn't hang in QEMU
OVMF_DIR="$(dirname "$OVMF_PATH")"
OVMF_VARS_TEMPLATE=""
for name in OVMF_VARS.fd OVMF_VARS_4M.fd edk2-x86_64-vars.fd; do
    if [ -f "$OVMF_DIR/$name" ]; then
        OVMF_VARS_TEMPLATE="$OVMF_DIR/$name"
        break
    fi
done

OVMF_VARS_WRITABLE=""
if [ -n "$OVMF_VARS_TEMPLATE" ]; then
    OVMF_VARS_WRITABLE="$(pwd)/ovmf_vars.fd"
    cp -f "$OVMF_VARS_TEMPLATE" "$OVMF_VARS_WRITABLE"
    echo "✅ OVMF NVRAM (vars) found: using writable copy for QEMU"
else
    echo "⚠️  OVMF_VARS not found - ExitBootServices may hang in QEMU"
    echo "   Install: sudo apt install ovmf (Ubuntu) or edk2-ovmf (Arch)"
fi
echo ""

# Create EFI disk image
echo "📦 Creating EFI disk image..."

if [ "$(uname -s)" = "Darwin" ]; then
    # macOS: hdiutil
    TEMP_DIR=$(mktemp -d)
    mkdir -p "$TEMP_DIR/EFI/BOOT"
    cp BOOTX64.EFI "$TEMP_DIR/EFI/BOOT/"
    cp ../../kernel/build/kernel64.bin "$TEMP_DIR/EFI/BOOT/"
    cat > "$TEMP_DIR/startup.nsh" << 'EOF'
@echo -off
echo "SOFIA OS - Auto-booting..."
FS0:
cd EFI\BOOT
BOOTX64.EFI
EOF
    echo "📁 Creating FAT32 disk image (macOS)..."
    hdiutil create -megabytes 50 -fs MS-DOS -volname "SOFIA_EFI" -srcfolder "$TEMP_DIR" -o sofia_uefi_test.dmg >/dev/null 2>&1 || {
        echo "❌ Failed to create disk image"
        rm -rf "$TEMP_DIR"
        exit 1
    }
    hdiutil convert sofia_uefi_test.dmg -format UDTO -o sofia_uefi_test.cdr >/dev/null 2>&1
    mv sofia_uefi_test.cdr sofia_uefi_test.img
    rm -f sofia_uefi_test.dmg
    rm -rf "$TEMP_DIR"
else
    # Linux: dd + mkfs.vfat + mtools
    echo "📁 Creating raw image and FAT32 filesystem..."
    dd if=/dev/zero of=sofia_uefi_test.img bs=1M count=50 status=none
    mkfs.vfat -F 32 -n "SOFIA_EFI" sofia_uefi_test.img >/dev/null 2>&1
    echo "📥 Copying files with mtools..."
    mmd -i sofia_uefi_test.img ::/EFI
    mmd -i sofia_uefi_test.img ::/EFI/BOOT
    mcopy -i sofia_uefi_test.img BOOTX64.EFI ::/EFI/BOOT/
    mcopy -i sofia_uefi_test.img ../../kernel/build/kernel64.bin ::/EFI/BOOT/
    # startup.nsh for shell auto-boot (optional)
    echo '@echo -off
echo "SOFIA OS - Auto-booting..."
FS0:
cd EFI\BOOT
BOOTX64.EFI' > startup.nsh
    mcopy -i sofia_uefi_test.img startup.nsh ::/
    rm -f startup.nsh
fi

echo "✅ EFI disk image created: sofia_uefi_test.img"
echo ""

# Launch QEMU with UEFI
echo "🚀 Launching QEMU with UEFI (OVMF)..."
echo ""
echo "Expected boot sequence:"
echo "  1. UEFI firmware loads"
echo "  2. BOOTX64.EFI runs (SOFIA bootloader)"
echo "  3. 64-bit kernel loads at 0x100000"
echo "  4. SOFIA OS logo appears with white/gray background"
echo "  5. Blinking cursor and keyboard input work"
echo "  6. Press TAB to cycle through 4 color themes"
echo ""
echo "Press Ctrl+C to exit QEMU"
echo ""

# QEMU display: cocoa on macOS, gtk on Linux (or default)
QEMU_DISPLAY=""
case "$(uname -s)" in
    Darwin)  QEMU_DISPLAY="-display cocoa" ;;
    Linux)   QEMU_DISPLAY="-display gtk" ;;
esac

# Build QEMU pflash args: CODE (readonly) + VARS (writable) if available
QEMU_PFLASH_OPTS=(-drive "if=pflash,format=raw,readonly=on,file=$OVMF_PATH")
if [ -n "$OVMF_VARS_WRITABLE" ] && [ -f "$OVMF_VARS_WRITABLE" ]; then
    QEMU_PFLASH_OPTS+=(-drive "if=pflash,format=raw,file=$OVMF_VARS_WRITABLE")
fi

qemu-system-x86_64 \
    "${QEMU_PFLASH_OPTS[@]}" \
    -drive file=sofia_uefi_test.img,format=raw,if=ide \
    -m 256M \
    -vga std \
    -net none \
    $QEMU_DISPLAY &

QEMU_PID=$!
echo "✅ QEMU started (PID: $QEMU_PID)"
echo "   Waiting for test..."

# Wait a bit then show status
sleep 3
if ps -p $QEMU_PID > /dev/null; then
    echo ""
    echo "✅ QEMU is running"
    echo "   Close the window when done testing"
else
    echo ""
    echo "❌ QEMU exited unexpectedly"
    exit 1
fi
