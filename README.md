OS Course
=========


Boot
----

You have just powered on your system.
The boot process consists of the following main stages:

> **Note** This section assumes an Intel x86-based PC.

> **Todo** This section assumes a BIOS-based boot. Extend it to cover UEFI-based boot.

1. **Motherboard:** An embedded microcontroller on the motherboard (Baseboard
   Management Controller) may start, and initialize motherboard components even
   before the CPU has started. Examples include [Fault Resilient
   Booting](https://www.intel.com/content/www/us/en/support/articles/000007197/server-products/server-boards.html)
   and the [Intel Management Engine](https://www.intel.com/content/www/us/en/support/articles/000008927/software/chipset-software.html).

1. **CPU Reset:** The CPU receives power, and initializes itself to a specific
   Reset state. Where is the Instruction Pointer? It points to a specific
   "Reset Vector". For Intel processors in general, this is 16 bytes below the
   last physical address; In the case of the i386, this is `0xFFFFFFF0`. More
   on this later on.

      ![Intel x86 memory map on reset](https://manybutfinite.com/img/boot/bootMemoryRegions.png)

1. **BIOS:** The motherboard maps the reset vector into BIOS ROM. This means the first
   instruction the CPU executes belongs to BIOS code. The BIOS jumps
   immediately into a lower address in ROM, initializes components on the
   motherboard/chipset, e.g., memory controller, RAM, interrupt controller,
   timer, and performs Power On Self Test (POST). It also looks for **Option
   ROMs** on the ISA/PCI bus, and [passes control to
   them](https://en.wikipedia.org/wiki/Option_ROM), one by one. One of the
   first ROMs which the BIOS jumps to contains the VGA BIOS, which initializes
   the display. Finally, the BIOS loads the first 512-byte sector of the chosen
   boot device (let's assume a hard disk) into a specific location in memory
   (`0000:07C00` in 8086 real mode), and jumps to it directly.

      ![A disk is a series of numbered blocks/sectors](https://manybutfinite.com/img/boot/masterBootRecord.png)

1. **MBR (Stage 1):** The first 512-byte sector of a block device is the
   "Master Boot Record", or MBR. Here is a typical MBR:

      ![Anatomy of the MBR](https://developer.ibm.com/developer/default/articles/l-linuxboot/images/fig2.gif)

   The MBR contains the MBR partition table and 446 bytes of 8086 code.
   This 446-byte long bootloader is often called the *Stage 1 boot loader*,
   following GRUB Legacy terminology.
   It can only use the BIOS for access to the rest of the data on disk.

   A Windows MBR looks for a partition marked as "active", loads its first sector,
   and jumps to it [chain-loading].

   Linux bootloaders include [GRUB 2](https://www.gnu.org/software/grub/), GRUB legacy,
   [SYSLINUX](https://wiki.syslinux.org/wiki/index.php), [LILO (obsolete)](https://www.joonet.de/lilo/).

   GRUB 2 calls its MBR / Stage 1 `boot.img`.

1. **GRUB 2 (Stage 1.5 / `core.img`):** Stage 1 doesn't have enough space to
   know how to access a filesystem, so it can only load a list of predefined
   sectors, a "block list". This list encodes the list of sectors where Stage
   1.5 lives.

   GRUB Legacy used a hack where it stored Stage 1.5 in the gap between the MBR
   and the start of the first partition, which for historic reasons must be >=
   sector 63. This leaves 31K for Stage 1.5.

   Similarly GRUB 2 stores `core.img` in the gap between the MBR and the start
   of the first partition, and it can't be more than 31K.

   Stage 1.5 switches the processor to protected mode, and loads Stage 2. It
   needs to have enough code to access the disk(s) and interpret the actual
   filesystem of the partition where Stage 2 resides, e.g., `ext4`.

   In GRUB 2, `core.img` can load any number of modules from `/boot/grub`
   dynamically. This set of modules constitutes the equivalent of Stage 2.

   LILO used a hardcoded block list inside the MBR to load the kernel directly.
   Similarly, GRUB uses a hardcoded list of consecutive sectors after sector
   `0` to load Stage 1.5.

   Why is GRUB 's method more resilient as users upgrade their systems /
   install new kernels?

1. **GRUB 2 (Stage 2 / dynamic modules):** GRUB 2 is now a mini-OS in its own
   right. It can load more dynamic modules, detect disks, assemble RAID arrays,
   decrypt encrypted partitions, access filesystems, as necessary.
   It interprets filesystem structures to load the kernel, e.g.,
   `/boot/vmlinuz-5.10.0-13-amd64` and initramfs, e.g.,
   `/boot/initrd.img-5.10.0-13-amd64` into memory.

1. **Linux kernel:** Finally, GRUB jumps to the kernel. The kernel has full control
   of the machine, it re-initializes the hardware it has embedded drivers for,
   and unpacks the initial filesystem [initramfs] in memory. The kernel mounts
   this initial filesystem as its root filesystem, and `execve()`s `/bin/init`.

   > **Todo** Add more information on the switch to protected mode --> `start_kernel()`
   > --> `rest_init()` --> `kernel_thread(kernel_init, ...)` --> `execve("/bin/init`
   > while in parallel --> `schedule_preempt_disabled()` --> `schedule()` which enters
   > the idle loop.

   > **Todo** Inspect with sequence with QEMU + KVM + gdb.

1. **Initramfs:** Load more drivers, access disks / resources on the network.
   Decrypt devices as necessary. Mount the final root filesystem, and pivot to it.
   > **Todo** Document `pivot_root(2)`, `switch_root(8)`.

Here is a visualization of the boot process:

   ![The Linux boot process](https://developer.ibm.com/developer/default/articles/l-linuxboot/images/fig1.gif)

Interesting resources:

   * [How computers boot up](https://manybutfinite.com/post/how-computers-boot-up/)
   * [Inside the Linux boot process](https://developer.ibm.com/articles/l-linuxboot/)
   * [GRUB 2 Images](https://www.gnu.org/software/grub/manual/grub/html_node/Images.html)
   * [GRUB 2 on Wikipedia](https://en.wikipedia.org/wiki/GNU_GRUB#Version_2_(GRUB))
   * [Kernel booting process](https://0xax.gitbooks.io/linux-insides/content/Booting/linux-bootstrap-1.html)


Boot sector
-----------

Let's assemble and boot a simple 512-byte boot sector using the BIOS.
File `boot/floppy0.raw.asm` defines a boot sector like this, adapted from
[here](https://en.wikibooks.org/wiki/X86_Assembly/Bootloaders).
   ```
   $ cd boot
   $ nasm -f bin floppy0.raw.asm -o floppy0.raw.bin
   $ qemu-system-i386 -drive if=floppy,index=0,format=raw,file=floppy0.raw.bin -display curses
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
      $ qemu-system-i386 -drive if=floppy,index=0,format=raw,file=floppy0.raw.bin -display curses -s -S
      ```

1. In a different terminal, start `gdb` and ask it to use QEMU as the remote
   target. Due to a [bug in the way QEMU interacts with
   gdb](https://sourceware.org/bugzilla/show_bug.cgi?id=22869),
   [duplicate here](https://gitlab.com/qemu-project/qemu/-/issues/141), you have to do
   some extra configuration on the gdb side to debug 16-bit x86 code in real mode.
      ```
      $ gdb
      (gdb) target remote localhost:1234
      (gdb) set tdesc filename i8086.xml
      (gdb) set architecture i8086
      ```

   > **Note**
1. Inspect the state of the VM. This is the state of the VM at reset, more on this below.
      ```
      (gdb) info registers
      ```

> **Note**
> The workaround to make QEMU work with gdb for 16-bit code in real mode is to
> define your own target description for gdb inside a new 'target.xml' file and
> then instruct gdb to use the `i8086` architecture. I used [this target description](https://gist.github.com/MatanShahar/1441433e19637cf1bb46b1aa38a90815)
> for this.
>
> You **must** use `qemu-system-i386` throughout this section, otherwise gdb will
> fail with
> ```
> Remote 'g' packet reply is too long (expected 308 bytes, got 536 bytes):
> ```
> See this GitHub comment for a more detailed explanation:
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

Use QEMU to inspect the current state of the VM, right after reset:

1. Press `Alt-2` to move to the QEMU monitor, and use the `info registers` command:
      ```
      (qemu) info registers
      ```

   Note the CS descriptor base is waaaay over 1MB (essentially,
   [Unreal mode](https://wiki.osdev.org/Unreal_Mode))

1. Note how the first command is a `JMP FAR` command:
      ```
      (qemu) x/i 0xfffffff0
      ```

1. Note how it jumps back into the ISA BIOS region, where QEMU has already mapped SeaBIOS.
      ```
      (qemu) info mtree
      ```

Use gdb to inspect the current state of the VM:

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

   > **Note**
   > Breakpoints must be 32-bit EIP addresses, see here for [some more context](https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr).

1. Inspect CPU registers:
      ```
      (gdb) info registers
      ```

> **Note**
> The legacy 8086 used `FFFF:0000` --> `0xFFFF0` as its reset vector, see section [System Reset](http://bitsavers.informatik.uni-stuttgart.de/components/intel/_dataBooks/1981_iAPX_86_88_Users_Manual.pdf).
> Note how `CS:IP` in QEMU's emulated i386 points to F000:FFF0 --> 0xFFFF0, at
> exactly the same location, right below 1MB of memory. This allows for
> backwards compatibility with the 8086.

Interesting resources:

   * [Intel 64 and IA-32 Architectures Developer's Manual: Vol.
     3A](https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html),
     the authoritative documentation on low-level programming in Assembly on
     the Intel x86 architecture.

   * [Legacy iAPX 86,88 User's
     Manual](http://bitsavers.informatik.uni-stuttgart.de/components/intel/_dataBooks/1981_iAPX_86_88_Users_Manual.pdf),
     a much older, much simpler manual by Intel for the 8086/88. Contains
     simple descriptions of how interrupts, ports, exceptions work. Ignore some
     really obsolete sections [PL/M?]

   * [Software initialization code at 0xFFFFFFF0H](https://stackoverflow.com/questions/9210296/software-initialization-code-at-0xfffffff0h), a discussion about the i386 reset vector, referencing Coreboot documentation.


BIOS
----

The BIOS (Basic Input/Output System) is the firmware in IBM PC compatible
systems which provides basic runtime services during system initialization and
boot up. Older Operating Systems, like MS-DOS, used it for I/O exclusively,
newer Operating Systems almost never call into the BIOS after starting up.

The BIOS provides services via interrupt handlers, similarly to how an OS
provides system calls to userspace process.

Interesting resources:

   * [Ralf Brown's Interrupt List](http://www.cs.cmu.edu/~ralf/files.html), the
     authoritative source for BIOS / DOS calls and programming in x86 Assembly.
   * [Ralf Brown's Interrupt List - HTML Version](https://www.ctyme.com/rbrown.htm),
     an HTML index of the same list.

SeaBIOS
-------

SeaBIOS is an open source BIOS implementation. QEMU uses SeaBIOS as its
canonical BIOS.


Build
"""""

> **TODO** Add instructions about how to download and build SeaBIOS and SeaVGABIOS with debug symbols.
> Use these artifacts with QEMU + gdb.


PIO - Port-Mapped I/O (PMIO)
----------------------------


PIO - Memory-Mapped I/O (MMIO)
------------------------------


Debian
------


Write your own OS
-----------------

Interesting resources

   * [OSDev Wiki](https://wiki.osdev.org/Expanded_Main_Page), a collection of articles on OS Development.
   * [The little book about OS development](https://littleosbook.github.io/), a very interesting book on writing your own OS.

