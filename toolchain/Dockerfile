FROM ubuntu:24.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential clang lld llvm \
    grub-efi-amd64-bin grub-pc-bin grub-common xorriso mtools dosfstools \
    gnu-efi \
    syslinux isolinux \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
