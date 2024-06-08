TARGET=i686
AS=$(TARGET)-elf-as
CC=$(TARGET)-elf-gcc

SRC_DIR=src
OBJ_DIR=obj
LNK_DIR=lnk
BIN_DIR=bin

ISO_DIR=iso
CFG_DIR=cfg

AS_FILES=boot.s
OB_FILES=$(AS_FILES:s=o)
LN_FILES=linker.ld

KERNEL_NAME=kernel
KERNEL_SRC_NAME=$(SRC_DIR)/$(KERNEL_NAME).c
KERNEL_OBJ_NAME=$(OBJ_DIR)/$(KERNEL_NAME).o
KERNEL_BIN_NAME=$(BIN_DIR)/$(KERNEL_NAME).elf

CFLAGS=-std=gnu99 -ffreestanding -O2 -Wall -Wextra -g
LFLAGS=-ffreestanding -O2 -nostdlib -lgcc -g

image: link
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL_BIN_NAME) $(ISO_DIR)/boot/
	cp $(CFG_DIR)/grub.cfg $(ISO_DIR)/boot/grub/
	grub-mkrescue $(ISO_DIR) -o $(KERNEL_NAME).iso 

link: kernel
	$(CC) -T $(LNK_DIR)/$(LN_FILES) -o $(KERNEL_BIN_NAME) $(OBJ_DIR)/$(OB_FILES) $(KERNEL_OBJ_NAME) $(LFLAGS)
	make validate

kernel: boot
	$(CC) -c $(KERNEL_SRC_NAME) -o $(KERNEL_OBJ_NAME) $(CFLAGS)

boot:
	$(AS) $(SRC_DIR)/$(AS_FILES) -o $(OBJ_DIR)/$(OB_FILES)
    
validate:
	@#check if the kernel bin is multiboot compatible
ifneq (0, $(shell if grub-file --is-x86-multiboot $(KERNEL_BIN_NAME); then echo 0; else echo 1; fi))
	@echo "ERROR: KERNEL EXECUTABLE NOT MULTIBOOT COMPATIBLE!"
endif


.PHONY:	run
run: image
	qemu-system-i386 -cdrom $(KERNEL_NAME).iso

.PHONY:	clean
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/* $(ISO_DIR)/ $(KERNEL_NAME).iso
