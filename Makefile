ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image bootloader kernel clean run

all: floppy_image

# Build the floppy image
floppy_image: bootloader kernel
	mkdir -p $(BUILD_DIR)
	# 1. Create a blank 1.44MB image file filled with zeros
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=1024 count=1440
	
	# 2. Inject the bootloader directly into Sector 0 (Bytes 0 - 512)
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc bs=512 count=1
	
	# 3. Inject the kernel directly into Sector 1 (Bytes 512 - 1024)
	dd if=$(BUILD_DIR)/kernel.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc bs=512 seek=1

# Compile bootloader
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: $(SRC_DIR)/bootloader/boot.asm
	mkdir -p $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

# Compile kernel
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: $(SRC_DIR)/kernel/main.asm
	mkdir -p $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

# Clean build files
clean:
	rm -rf $(BUILD_DIR)/*

# Quick boot shortcut
run:
	qemu-system-x86_64 -fda $(BUILD_DIR)/main_floppy.img