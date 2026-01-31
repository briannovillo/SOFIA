#!/bin/bash
# SOFIA OS - 64-bit Kernel Build Script (for UEFI)

set -e

# Use DOCKER_CMD if set (e.g. "sudo docker" when user is not in docker group)
DOCKER="${DOCKER_CMD:-docker}"

echo "🔧 Building SOFIA OS Kernel (64-bit for UEFI)"
echo "======================================"

# Check Docker access first
if ! $DOCKER info &>/dev/null; then
    echo "❌ No se puede conectar con Docker."
    if $DOCKER info 2>&1 | grep -q "permission denied"; then
        echo ""
        echo "   Solución: añade tu usuario al grupo docker:"
        echo "     sudo usermod -aG docker \$USER"
        echo "   Luego cierra sesión y vuelve a entrar (o ejecuta: newgrp docker)"
        echo ""
        echo "   O usa sudo solo para Docker:"
        echo "     DOCKER_CMD=\"sudo docker\" ./build-kernel64.sh"
    fi
    exit 1
fi

# Check if Docker toolchain exists
if ! $DOCKER image inspect sofia-uefi-toolchain &>/dev/null; then
    echo "❌ Docker toolchain not found!"
    echo "   Build it first:"
    echo "   cd ../toolchain && $DOCKER build -t sofia-uefi-toolchain ."
    echo ""
    echo "   If you need sudo: DOCKER_CMD=\"sudo docker\" ./build-kernel64.sh"
    exit 1
fi

echo "📦 Compiling 64-bit kernel modules..."

mkdir -p build

# Compile using Docker
$DOCKER run --rm --platform linux/amd64 \
    -v "$(pwd)":/work \
    -w /work/arch/x86_64 \
    sofia-uefi-toolchain \
    bash -c "
        apt-get update -qq && \
        apt-get install -y -qq nasm && \
        nasm -f bin kernel64.asm -o ../../build/kernel64.bin
    "

# Check if compilation was successful
if [ -f "build/kernel64.bin" ]; then
    SIZE=$(du -h build/kernel64.bin | cut -f1)
    echo "✅ 64-bit Kernel compiled successfully: $SIZE"
    echo ""
    echo "Modules included:"
    echo "  - video/vga.asm (VGA operations)"
    echo "  - video/cursor.asm (Cursor rendering)"
    echo "  - ui/logo.asm (SOFIA logo)"
    echo "  - drivers/keyboard.asm (Keyboard driver)"
    echo "  - drivers/speaker.asm (PC speaker)"
    echo ""
else
    echo "❌ Compilation failed!"
    exit 1
fi
