#!/bin/bash
# Build script for SOFIA OS modular kernel

set -e

echo "🔧 Building SOFIA OS Kernel (Modular)"
echo "======================================"

# Change to kernel directory
cd "$(dirname "$0")"

# Build kernel using Docker
echo "📦 Compiling kernel modules..."
docker run --rm --platform linux/amd64 \
  -v "$(pwd)":/work \
  -w /work/arch/x86_64 \
  sofia-uefi-toolchain \
  bash -c "
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y -qq nasm > /dev/null 2>&1
    nasm -f bin kernel.asm -o ../../build/kernel.bin
  "

# Check if build succeeded
if [ -f "build/kernel.bin" ]; then
    SIZE=$(ls -lh build/kernel.bin | awk '{print $5}')
    echo "✅ Kernel compiled successfully: $SIZE"
    echo ""
    echo "Modules included:"
    echo "  - video/vga.asm (VGA operations)"
    echo "  - video/cursor.asm (Cursor rendering)"
    echo "  - ui/logo.asm (SOFIA logo)"
    echo "  - drivers/keyboard.asm (Keyboard driver)"
    echo "  - drivers/speaker.asm (PC speaker)"
else
    echo "❌ Build failed"
    exit 1
fi
