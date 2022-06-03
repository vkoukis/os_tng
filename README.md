OS Course
=========

Boot sector
-----------

boot/floppy0.asm defines a simple 512-byte boot sector for BIOS-based boot, adapted from
[here](https://en.wikibooks.org/wiki/X86_Assembly/Bootloaders).
   ```
   $ cd boot
   $ nasm -f bin floppy0.asm
   $ qemu-system-x86_64 -drive if=floppy,index=0,format=raw,file=floppy0.bin -display curses
   ```

To quit the VM:

   ```
   [Move to the QEMU monitor prompt with Alt-2]
   (qemu) quit
   ```


Interesting resources:

   * Wikibook on x86 assembly:
     https://en.wikibooks.org/wiki/X86_Assembly
