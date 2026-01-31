#!/bin/bash
# SOFIA OS - UEFI Bootloader Build Script

set -e

# Use DOCKER_CMD if set (e.g. "sudo docker" when user is not in docker group)
DOCKER="${DOCKER_CMD:-docker}"

echo "🔧 Building SOFIA OS UEFI Bootloader"
echo "======================================"

# Check Docker access first
if ! $DOCKER info &>/dev/null; then
    echo "❌ Cannot connect to Docker."
    if $DOCKER info 2>&1 | grep -q "permission denied"; then
        echo ""
        echo "   Solution: add your user to the docker group:"
        echo "     sudo usermod -aG docker \$USER"
        echo "   Then log out and back in (or run: newgrp docker)"
        echo ""
        echo "   Or use sudo only for Docker:"
        echo "     DOCKER_CMD=\"sudo docker\" ./build-uefi.sh"
    fi
    exit 1
fi

# Check if Docker toolchain exists
if ! $DOCKER image inspect sofia-uefi-toolchain &>/dev/null; then
    echo "❌ Docker toolchain not found!"
    echo "   Build it first:"
    echo "   cd ../../toolchain && $DOCKER build -t sofia-uefi-toolchain ."
    echo ""
    echo "   If you need sudo: DOCKER_CMD=\"sudo docker\" ./build-uefi.sh"
    exit 1
fi

echo "📦 Compiling UEFI bootloader..."

# Compile using Docker with GNU-EFI
$DOCKER run --rm --platform linux/amd64 \
    -v "$(pwd)":/work \
    -w /work \
    sofia-uefi-toolchain \
    bash -c "
        apt-get update -qq && \
        apt-get install -y -qq gnu-efi gcc make && \
        make clean && \
        make
    "

# Check if compilation was successful
if [ -f "BOOTX64.EFI" ]; then
    SIZE=$(du -h BOOTX64.EFI | cut -f1)
    echo "✅ UEFI bootloader compiled successfully: $SIZE"
    echo ""
    echo "Output file: BOOTX64.EFI"
    echo ""
    echo "Next steps:"
    echo "  1. Create EFI partition: ./create-efi-usb.sh"
    echo "  2. Test with QEMU: ./test-uefi-qemu.sh"
else
    echo "❌ Compilation failed!"
    exit 1
fi
