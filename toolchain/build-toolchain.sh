#!/bin/bash
# SOFIA OS - Build Docker toolchain image

set -e

DOCKER="${DOCKER_CMD:-docker}"

echo "🔧 Building SOFIA UEFI toolchain (Docker image)"
echo "==============================================="

if ! $DOCKER info &>/dev/null; then
    echo "❌ Cannot connect to Docker."
    if $DOCKER info 2>&1 | grep -q "permission denied"; then
        echo ""
        echo "   Solution:"
        echo "     sudo usermod -aG docker \$USER"
        echo "     (then: newgrp docker  or  log out and back in)"
        echo ""
        echo "   Or run this script with sudo for Docker:"
        echo "     DOCKER_CMD=\"sudo docker\" ./build-toolchain.sh"
    fi
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
$DOCKER build -t sofia-uefi-toolchain .

echo ""
echo "✅ Image created: sofia-uefi-toolchain"
echo ""
echo "Next: build bootloader and kernel:"
echo "  cd ../bootloader/uefi && ./build-uefi.sh"
echo "  cd ../../kernel && ./build-kernel64.sh"
echo ""
