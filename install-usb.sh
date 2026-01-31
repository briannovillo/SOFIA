#!/bin/bash
# SOFIA OS - USB Installation Script
# Run with: sudo ./install-usb.sh

set -e

DEVICE=/dev/disk4

echo "🔧 SOFIA OS - Installing to USB"
echo "================================="
echo ""
echo "Device: $DEVICE"
echo ""

# Step 3: Install bootloader
echo "📦 Step 3/4: Installing bootloader (sector 0)..."
dd if=bootloader/boot_sector_debug.bin of=$DEVICE bs=512 count=1
echo "✅ Bootloader installed"
echo ""

# Step 4: Install kernel
echo "📦 Step 4/4: Installing kernel (sector 2)..."
dd if=kernel/build/kernel.bin of=$DEVICE bs=512 seek=2 conv=notrunc
echo "✅ Kernel installed"
echo ""

# Sync and eject
echo "💾 Syncing and ejecting..."
sync
diskutil eject $DEVICE

echo ""
echo "✅ Bootable USB created successfully!"
echo ""
echo "🎨 New features in this version:"
echo "  • Press TAB to cycle through 4 color themes"
echo "  • Hardware-optimized (no flickering)"
echo ""
echo "Next steps:"
echo "  1. Restart your computer"
echo "  2. Enter BIOS/UEFI (F2, F10, etc.)"
echo "  3. Set Boot Mode = Legacy"
echo "  4. Disable Secure Boot"
echo "  5. Boot from USB"
echo ""
