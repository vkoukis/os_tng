LD = ld
NASM = nasm
OBJCOPY = objcopy
DD = dd

.PHONY: all
all: floppy0.raw.bin floppy1.raw.bin floppy2.raw.bin floppy3.raw.bin floppy4.raw.bin \
     floppy0.dbg.bin floppy1.dbg.bin floppy2.dbg.bin floppy3.dbg.bin floppy4.dbg.bin \
     floppy0.dbg.elf floppy1.dbg.elf floppy2.dbg.elf floppy3.dbg.elf floppy4.dbg.elf

.PHONY: clean
clean:
	rm -f *.bin *.bin.full *.elf *.o

# Assemble via NASM -> ld -> objcopy to have elf files with debugging information
%.dbg.o: %.dbg.asm
	$(NASM) -f elf32 -g -F dwarf $< -o $@

%.dbg.elf: %.dbg.o
	$(LD) -Ttext=0x7c00 -melf_i386 $< -o $@

%.dbg.dump: %.dbg.elf
	$(OBJCOPY) -O binary $< $@

%.dbg.bin: %.dbg.dump
	$(DD) if=$< of=$@ bs=512 count=1


# Assemble directly from NASM into flat binaries
%.raw.bin: %.raw.asm
	$(NASM) -f bin $< -o $@
