#!/bin/bash
set -e

echo "=== SOFIA OS - Create Bootable USB ==="
echo ""

# Check device
if [ -z "$1" ]; then
    echo "Usage: $0 /dev/diskX"
    echo ""
    echo "Available USB devices:"
    diskutil list | grep -A3 "external"
    exit 1
fi

DISK=$1
DISK_NUM=$(echo $DISK | sed 's/\/dev\/disk//')

echo "⚠️  WARNING: This will ERASE everything on $DISK"
echo ""
read -p "Type 'YES' to continue: " confirm

if [ "$confirm" != "YES" ]; then
    echo "Cancelled"
    exit 1
fi

cd "$(dirname "$0")/.."

echo ""
echo "1. Unmounting disk..."
diskutil unmountDisk force $DISK

echo "2. Creating MBR/FAT32 partition..."
diskutil eraseDisk MS-DOS SOFIA MBR $DISK

echo "3. Unmounting again..."
diskutil unmountDisk force $DISK

echo "4. Installing boot sector..."
sudo dd if=bootloader/boot_sector_debug.bin of=$DISK bs=512 count=1

echo "5. Writing kernel to sector 2..."
sudo dd if=kernel/build/kernel_flat.bin of=$DISK bs=512 seek=2 conv=notrunc

echo "6. Syncing..."
sync

echo ""
echo "✅ Bootable USB created!"
echo ""
echo "Now you can:"
echo "  - Eject: diskutil eject $DISK"
echo "  - Use on ASUS/HP with Legacy BIOS"
echo ""
