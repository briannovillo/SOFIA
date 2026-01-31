#!/bin/bash
# SOFIA OS - Create UEFI Bootable USB (macOS)
# Creates a GPT partition with EFI System Partition

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: sudo $0 /dev/diskN"
    echo ""
    echo "Find your USB device with: diskutil list"
    exit 1
fi

DEVICE=$1

echo "🔧 SOFIA OS - Creating UEFI Bootable USB"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will ERASE all data on $DEVICE"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run with sudo"
    exit 1
fi

# Check if files exist
if [ ! -f "BOOTX64.EFI" ]; then
    echo "❌ BOOTX64.EFI not found!"
    echo "   Run ./build-uefi.sh first"
    exit 1
fi

if [ ! -f "../../kernel/build/kernel64.bin" ]; then
    echo "❌ kernel64.bin not found!"
    echo "   Build 64-bit kernel first: cd ../../kernel && ./build-kernel64.sh"
    exit 1
fi

echo ""
echo "📦 Step 1/5: Unmounting device..."
diskutil unmountDisk $DEVICE || true

echo "📦 Step 2/5: Creating GPT partition table with EFI System Partition..."
diskutil eraseDisk MS-DOS SOFIA_EFI GPT $DEVICE

# The device might be renamed, find the EFI partition
EFI_PARTITION="${DEVICE}s1"

echo "📦 Step 3/5: Mounting EFI partition..."
MOUNT_POINT="/Volumes/SOFIA_EFI"

# Wait a moment for the system to recognize the partition
sleep 2

# Create EFI directory structure
echo "📁 Step 4/5: Creating EFI directory structure..."
mkdir -p "$MOUNT_POINT/EFI/BOOT"

# Copy bootloader and 64-bit kernel
echo "📥 Step 5/5: Copying files..."
cp BOOTX64.EFI "$MOUNT_POINT/EFI/BOOT/"
cp ../../kernel/build/kernel64.bin "$MOUNT_POINT/EFI/BOOT/"

echo "✅ Files copied:"
ls -lh "$MOUNT_POINT/EFI/BOOT/"

# Sync and eject
echo ""
echo "💾 Syncing and ejecting..."
sync
diskutil eject $DEVICE

echo ""
echo "✅ UEFI Bootable USB created successfully!"
echo ""
echo "🎨 Features in this version:"
echo "  • UEFI boot support (for modern PCs without CSM)"
echo "  • Press TAB to cycle through 4 color themes"
echo "  • Hardware-optimized (no flickering)"
echo ""
echo "Next steps:"
echo "  1. Insert USB into target PC (HP All-in-One)"
echo "  2. Enter BIOS/UEFI (F2, F10, F12, or ESC)"
echo "  3. Ensure Boot Mode = UEFI (NOT Legacy)"
echo "  4. Disable Secure Boot if enabled"
echo "  5. Select USB drive from boot menu"
echo "  6. SOFIA OS should boot!"
echo ""
