OS Course
=========

Boot sector
-----------

Let's assemble and boot a simple 512-byte boot sector using the BIOS.
File `boot/floppy0.asm` defines a boot sector like this, adapted from
[here](https://en.wikibooks.org/wiki/X86_Assembly/Bootloaders).
   ```
   $ cd boot
   $ nasm -f bin floppy0.asm
   $ qemu-system-i386 -drive if=floppy,index=0,format=raw,file=floppy0.bin -display curses
   ```

To quit the VM:

   ```
   [Move to the QEMU monitor prompt with Alt-2]
   (qemu) quit
   ```


Interesting resources:

   * [Wikibook on x86 assembly](https://en.wikibooks.org/wiki/X86_Assembly)


QEMU + gdb
----------

Let's combine [QEMU with
gdb](https://qemu-project.gitlab.io/qemu/system/gdb.html) so we can look at the
boot process instruction by instruction. QEMU supports a gdb "stub"; it becomes
a remote debugging target for the GNU debugger, `gdb`, so we can use gdb to
inspect and manipulate VM state. This is the equivalent of using a hardware
debugger to inspect and manipulate the machine directly.

1. Start QEMU, but have it wait for a connection from gdb at `localhost:1234`
   [option `-s`], without starting the emulated CPU at all [option `-S`]:

      ```
      $ qemu-system-i386 -drive if=floppy,index=0,format=raw,file=floppy0.bin -display curses -s -S
      ```

1. In a different terminal, start `gdb` and ask it to use QEMU as the remote
   target. Due to a [bug in the way QEMU interacts with
   gdb](https://sourceware.org/bugzilla/show_bug.cgi?id=22869), you have to do
   some extra configuration on the gdb side to debug 16-bit x86 code in real mode.

      ```
      $ gdb
      (gdb) target remote localhost:1234
      (gdb) set tdesc filename i8086.xml
      (gdb) set architecture i8086
      ```

1. Inspect the state of the VM. This is the state of the VM at reset, more on this below.
      ```
      (gdb) info registers
      ```

> **Note**
> The workaround to make QEMU work with gdb for 16-bit code in real mode is to
> define your own target description for gdb inside a new 'target.xml' file and
> then instruct gdb to use the `i8086` architecture. I used [this target
> description](https://gist.github.com/MatanShahar/1441433e19637cf1bb46b1aa38a90815
> for this).
>
> You *must* use `qemu-system-i386` throughout this section, otherwise gdb will
> fail with
> ```
> Remote 'g' packet reply is too long (expected 308 bytes, got 536 bytes):
> ```
> See this GitHub comment for detailed instructions:
https://gist.github.com/MatanShahar/1441433e19637cf1bb46b1aa38a90815?permalink_comment_id=3315921#gistcomment-3315921

Interesting resources:

   * [Intel System Debugger](https://www.intel.com/content/www/us/en/develop/documentation/get-started-with-sbu-linux/top/intel-system-debugger.html), a hardware debugger.

   * [QEMU support for
     GDB](https://qemu-project.gitlab.io/qemu/system/gdb.html) for more details
     on how QEMU works with GDB.

   * [`qemu-system-i386` manual
     page](https://manpages.debian.org/bullseye/qemu-system-x86/qemu-system-i386.1.en.html)
     for all the different options QEMU accepts at the command line.

   * [QEMU and GDB
     reference](https://www.cs.utexas.edu/~dahlin/Classes/439/ref/qemu-gdb-reference.html)

> **Todo**
> Define a simple gdb startup script to simplify working with 16-bit code in real-mode, with Intel syntax.


Reset vector
------------

Let's use gdb to inspect the current state of the VM.

1. Disassemble 10 instructions:
      ```
      (gdb) x/10i 0xffff0
      ```

1. Show 10 bytes in hexadecimal:
      ```
      (gdb) x/10xb 0xffffffff0
      ```

1. Show 10 bytes in hexadecimal:
      ```
      (gdb) x/10xb 0xffff0
      ```

   > **Note:***
   > Breakpoints must be 32-bit EIP addresses:
   > https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr

1. Inspect registers:
      ```
      (gdb) info registers
      ```

   Note CS:IP points to f000:fff0 --> 0xffff0, right below 1MB of memory

> **Note**
> The legacy 8086 uses `FFFF:0000` as its reset vector

Interesting resources:

   * [Intel 64 and IA-32 Architectures Developer's Manual: Vol.
     3A](https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html),
     the authoritative documentation on low-level programming in assembly on
     the Intel x86 architecture.

   * [Legacy iAPX 86,88 User's
     Manual](http://bitsavers.informatik.uni-stuttgart.de/components/intel/_dataBooks/1981_iAPX_86_88_Users_Manual.pdf),
     a much older, much simpler manual by Intel for the 8086/88. Contains
     simple descriptions of how interrupts, ports, exceptions work. Ignore some
     really obsolete sections [PL/M?]
