#!/bin/bash
# SOFIA OS - QEMU Test Script
# Quick test before creating bootable USB

set -e

echo "🧪 SOFIA OS - QEMU Test"
echo "======================="
echo ""

# Check if binaries exist
if [ ! -f "bootloader/boot_sector_debug.bin" ]; then
    echo "❌ Error: bootloader/boot_sector_debug.bin not found"
    echo "   Run: cd bootloader && compile bootloader first"
    exit 1
fi

if [ ! -f "kernel/build/kernel.bin" ]; then
    echo "❌ Error: kernel/build/kernel.bin not found"
    echo "   Run: cd kernel && ./build-kernel.sh"
    exit 1
fi

# Check if QEMU is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "❌ Error: QEMU not installed"
    echo ""
    echo "Install QEMU:"
    echo "  macOS:   brew install qemu"
    echo "  Linux:   sudo apt install qemu-system-x86"
    echo "  Windows: https://www.qemu.org/download/"
    exit 1
fi

echo "✅ Bootloader found: $(ls -lh bootloader/boot_sector_debug.bin | awk '{print $5}')"
echo "✅ Kernel found: $(ls -lh kernel/build/kernel.bin | awk '{print $5}')"
echo "✅ QEMU installed: $(qemu-system-x86_64 --version | head -1)"
echo ""

# Create test image
echo "📦 Creating test image..."
dd if=/dev/zero of=sofia_test.img bs=1M count=1 2>/dev/null

# Install bootloader
echo "💿 Installing bootloader (sector 0)..."
dd if=bootloader/boot_sector_debug.bin of=sofia_test.img bs=512 count=1 conv=notrunc 2>/dev/null

# Install kernel
echo "🔧 Installing kernel (sector 2)..."
dd if=kernel/build/kernel.bin of=sofia_test.img bs=512 seek=2 conv=notrunc 2>/dev/null

echo ""
echo "✅ Test image created: sofia_test.img"
echo ""
echo "🚀 Launching QEMU..."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  What to expect:"
echo "  ✓ White background screen"
echo "  ✓ SOFIA logo (ASCII art)"
echo "  ✓ Subtitle: 'First AI Operating System'"
echo "  ✓ Blinking cursor"
echo "  ✓ Type to test keyboard input"
echo ""
echo "  Keyboard shortcuts:"
echo "  • Ctrl+Alt+G - Release mouse"
echo "  • Ctrl+Alt+Q - Quit QEMU"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Launch QEMU
qemu-system-x86_64 \
  -drive file=sofia_test.img,format=raw \
  -m 128M \
  -vga std \
  -display cocoa

echo ""
echo "✅ QEMU test complete"
echo ""
echo "Next steps:"
echo "  1. If everything looks good → Create bootable USB"
echo "  2. If something is broken → Fix and run this script again"
echo ""
