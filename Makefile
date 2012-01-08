VERSION=0.01
NAME=ATLAS

CC=nasm
out_dir=./bin/
INC=./inc/
SCRIPT=./script/
CFLAGS=-f elf32 -I $(INC) 
LDFLAGS=-melf_i386 -T $(SCRIPT)
OBJ=*.o
TARGET="NONE"

# Start point of making Atlas 
# By default if there is no extra options set, 
# the bootloader will produce a linkable object file. 
# that requires the linker script to compile with. 
atlas: boot.o 
	ld -r $(LDFLAGS)elf.ld $(out_dir)$(OBJ) -o ./Atlas.o 

target: atlas 
	dd if=/dev/zero of=$(out_dir)fluff.bin bs=1M count=10
	ld $(LDFLAGS)complete.ld Atlas.o $(TARGET) -o ./bin/Atlas_Complete.bin
	cat $(out_dir)Atlas_Complete.bin $(out_dir)/fluff.bin > Atlas.img

boot.o:
	mkdir -p ./bin/
	$(CC) $(CFLAGS) ./boot/boot.asm -o $(out_dir)boot.o
	$(CC) $(CFLAGS) ./boot/init.asm -o $(out_dir)init.o


clean: 
	@echo "Cleaning..."
	@rm -rf $(out_dir)
	@rm -f ./Atlas.o 
	@rm -f ./Atlas_Complete.img

