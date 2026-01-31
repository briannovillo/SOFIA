# SOFIA OS - UEFI Bootloader Makefile
# Compiles bootloader.c to BOOTX64.EFI using GNU-EFI

ARCH            = x86_64
OBJS            = bootloader.o minimal_stub.o
TARGET          = BOOTX64.EFI
EFIINC          = /usr/include/efi
EFIINCS         = -I$(EFIINC) -I$(EFIINC)/$(ARCH) -I$(EFIINC)/protocol
LIB             = /usr/lib
EFILIB          = /usr/lib
EFI_CRT_OBJS    = $(EFILIB)/crt0-efi-$(ARCH).o
EFI_LDS         = $(EFILIB)/elf_$(ARCH)_efi.lds

CFLAGS          = $(EFIINCS) -fno-stack-protector -fpic \
                  -fshort-wchar -mno-red-zone -Wall -DEFI_FUNCTION_WRAPPER
ifeq ($(ARCH),x86_64)
  CFLAGS += -DEFIX64
endif

LDFLAGS         = -nostdlib -znocombreloc -T $(EFI_LDS) -shared \
                  -Bsymbolic -L $(EFILIB) -L $(LIB) $(EFI_CRT_OBJS)

all: $(TARGET)

bootloader.o: bootloader.c
	gcc $(CFLAGS) -c $< -o $@

transition.o: transition.S
	gcc $(CFLAGS) -c $< -o $@

bootloader.so: $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@ -lefi -lgnuefi

$(TARGET): bootloader.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
	        -j .dynsym -j .rel -j .rela -j .reloc \
	        --target=efi-app-$(ARCH) $^ $@

clean:
	rm -f $(OBJS) bootloader.so $(TARGET)

.PHONY: all clean
