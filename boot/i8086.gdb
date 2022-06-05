# Special mode for GDB that allows to debug/disassemble REAL MODE x86 code
#
# It has been designed to be used with QEMU or BOCHS gdb-stub
#
# 08/2011 Hugo Mercier - GPL v3 license
#
# Freely inspired from "A user-friendly gdb configuration file" widely available
# on the Internet

set confirm off
set verbose off
set prompt (gdb-i8086)\ 

set output-radix 0d10
set input-radix 0d10

# These make gdb never pause in its output
set height 0
set width 0

# Intel syntax
set disassembly-flavor intel
# Real mode
set architecture i8086

set $SHOW_CONTEXT = 1

set $REAL_MODE = 1

# By default A20 is present
set $ADDRESS_MASK = 0x1FFFFF

# nb of instructions to display
set $CODE_SIZE = 10

define i86-enable-a20
  set $ADDRESS_MASK = 0x1FFFFF
end
define i86-disable-a20
  set $ADDRESS_MASK = 0x0FFFFF
end

# convert segment:offset address to physical address
define i86-r2p
  if $argc < 2
    printf "Arguments: segment offset\n"
  else
    set $ADDR = (((unsigned long)$arg0 & 0xFFFF) << 4) + (((unsigned long)$arg1 & 0xFFFF) & $ADDRESS_MASK)
    printf "0x%05X\n", $ADDR
  end
end
document i86-r2p
Convert segment:offset address to physical address
Set the global variable $ADDR to the computed one
end

# get address of Interruption
define i86-int_addr
  if $argc < 1
    printf "Argument: interruption_number\n"
  else
    set $offset = (unsigned short)*($arg0 * 4)
    set $segment = (unsigned short)*($arg0 * 4 + 2)
    i86-r2p $segment $offset
    printf "%04X:%04X\n", $segment, $offset
  end
end
document i86-int_addr
Get address of interruption
end

define i86-compute_regs
  set $rax = ((unsigned long)$eax & 0xFFFF)
  set $rbx = ((unsigned long)$ebx & 0xFFFF)
  set $rcx = ((unsigned long)$ecx & 0xFFFF)
  set $rdx = ((unsigned long)$edx & 0xFFFF)
  set $rsi = ((unsigned long)$esi & 0xFFFF)
  set $rdi = ((unsigned long)$edi & 0xFFFF)
  set $rbp = ((unsigned long)$ebp & 0xFFFF)
  set $rsp = ((unsigned long)$esp & 0xFFFF)
  set $rcs = ((unsigned long)$cs & 0xFFFF)
  set $rds = ((unsigned long)$ds & 0xFFFF)
  set $res = ((unsigned long)$es & 0xFFFF)
  set $rss = ((unsigned long)$ss & 0xFFFF)
  set $rip = ((((unsigned long)$cs & 0xFFFF) << 4) + ((unsigned long)$eip & 0xFFFF)) & $ADDRESS_MASK
  set $r_ss_sp = ((((unsigned long)$ss & 0xFFFF) << 4) + ((unsigned long)$esp & 0xFFFF)) & $ADDRESS_MASK
  set $r_ss_bp = ((((unsigned long)$ss & 0xFFFF) << 4) + ((unsigned long)$ebp & 0xFFFF)) & $ADDRESS_MASK
end

define i86-print_regs
  printf "AX: %04X BX: %04X ", $rax, $rbx
  printf "CX: %04X DX: %04X\n", $rcx, $rdx
  printf "SI: %04X DI: %04X ", $rsi, $rdi
  printf "SP: %04X BP: %04X\n", $rsp, $rbp
  printf "CS: %04X DS: %04X ", $rcs, $rds
  printf "ES: %04X SS: %04X\n", $res, $rss
  printf "\n"
  printf "IP: %04X EIP:%08X\n", ((unsigned short)$eip & 0xFFFF), $eip
  printf "CS:IP: %04X:%04X (0x%05X)\n", $rcs, ((unsigned short)$eip & 0xFFFF), $rip
  printf "SS:SP: %04X:%04X (0x%05X)\n", $rss, $rsp, $r_ss_sp
  printf "SS:BP: %04X:%04X (0x%05X)\n", $rss, $rbp, $r_ss_bp
end
document i86-print_regs
Print CPU registers
end

define i86-print_eflags
    printf "OF <%d>  DF <%d>  IF <%d>  TF <%d>",\
           (($eflags >> 0xB) & 1), (($eflags >> 0xA) & 1), \
           (($eflags >> 9) & 1), (($eflags >> 8) & 1)
    printf "  SF <%d>  ZF <%d>  AF <%d>  PF <%d>  CF <%d>\n",\
           (($eflags >> 7) & 1), (($eflags >> 6) & 1),\
           (($eflags >> 4) & 1), (($eflags >> 2) & 1), ($eflags & 1)
    printf "ID <%d>  VIP <%d> VIF <%d> AC <%d>",\
           (($eflags >> 0x15) & 1), (($eflags >> 0x14) & 1), \
           (($eflags >> 0x13) & 1), (($eflags >> 0x12) & 1)
    printf "  VM <%d>  RF <%d>  NT <%d>  IOPL <%d>\n",\
           (($eflags >> 0x11) & 1), (($eflags >> 0x10) & 1),\
           (($eflags >> 0xE) & 1), (($eflags >> 0xC) & 3)
end
document i86-print_eflags
Print eflags register.
end

# dump content of bytes in memory
# arg0 : addr
# arg1 : nb of bytes
define i86-_dump_memb
  if $argc < 2
    printf "Arguments: address number_of_bytes\n"
  else
    set $_nb = $arg1
    set $_i = 0
    set $_addr = $arg0
    while ($_i < $_nb)
      printf "%02X ", *((unsigned char*)$_addr + $_i)
      set $_i++
    end
  end
end

# dump content of memory in words
# arg0 : addr
# arg1 : nb of words
define i86-_dump_memw
  if $argc < 2
    printf "Arguments: address number_of_words\n"
  else
    set $_nb = $arg1
    set $_i = 0
    set $_addr = $arg0
    while ($_i < $_nb)
      printf "%04X ", *((unsigned short*)$_addr + $_i)
      set $_i++
    end
  end
end

# display data at given address
define i86-print_data
       if ($argc > 0)
       	  set $seg = $arg0
	  set $off = $arg1
	  set $raddr = ($arg0 << 16) + $arg1
	  set $maddr = ($arg0 << 4) + $arg1

	  set $w = 16
	  set $i = (int)0
	  while ($i < 4)
		printf "%08X: ", ($raddr + $i * $w)
	  	set $j = (int)0
		while ($j < $w)
		      printf "%02X ", *(unsigned char*)($maddr + $i * $w + $j)
		      set $j++
		end
		printf " "
	  	set $j = (int)0
		while ($j < $w)
		      set $c = *(unsigned char*)($maddr + $i * $w + $j)
		      if ($c > 32) && ($c < 128)
		      	 printf "%c", $c
		      else
			printf "."
		      end
		      set $j++
		end
		printf "\n"
		set $i++
	  end
       end
end

define i86-context
  printf "---------------------------[ STACK ]---\n"
  i86-_dump_memw $r_ss_sp 8
  printf "\n"
  set $_a = $r_ss_sp + 16
  i86-_dump_memw $_a 8
  printf "\n"
  printf "---------------------------[ DS:SI ]---\n"
  i86-print_data $ds $rsi
  printf "---------------------------[ ES:DI ]---\n"
  i86-print_data $es $rdi

  printf "----------------------------[ CPU ]----\n"
  i86-print_regs
  i86-print_eflags
  printf "---------------------------[ CODE ]----\n"

  set $_code_size = $CODE_SIZE

  # disassemble
  # first call x/i with an address
  # subsequent calls to x/i will increment address
  if ($_code_size > 0)
    x /i $rip
    set $_code_size--
  end
  while ($_code_size > 0)
    x /i
    set $_code_size--
  end
end
document i86-context
Print context window, i.e. regs, stack, ds:esi and disassemble cs:eip.
end

define hook-stop
  i86-compute_regs
  if ($SHOW_CONTEXT > 0)
    i86-context
  end
end
document hook-stop
!!! FOR INTERNAL USE ONLY - DO NOT CALL !!!
end

# add a breakpoint on an interrupt
define i86-break_int
    set $offset = (unsigned short)*($arg0 * 4)
    set $segment = (unsigned short)*($arg0 * 4 + 2)

    break *$offset
end

define i86-break_int_if_ah
  if ($argc < 2)
    printf "Arguments: INT_N AH\n"
  else
    set $addr = (unsigned short)*($arg0 * 4)
    set $segment = (unsigned short)*($arg0 * 4 + 2)
    break *$addr if ((unsigned long)$eax & 0xFF00) == ($arg1 << 8)
  end
end
document i86-break_int_if_ah
Install a breakpoint on INT N only if AH is equal to the expected value
end

define i86-break_int_if_ax
  if ($argc < 2)
    printf "Arguments: INT_N AX\n"
  else
    set $addr = (unsigned short)*($arg0 * 4)
    set $segment = (unsigned short)*($arg0 * 4 + 2)
    break *$addr if ((unsigned long)$eax & 0xFFFF) == $arg1
  end
end
document i86-break_int_if_ax
Install a breakpoint on INT N only if AX is equal to the expected value
end

define i86-stepo
  ## we know that an opcode starting by 0xE8 has a fixed length
  ## for the 0xFF opcodes, we can enumerate what is possible to have

  set $lip = $rip
  set $offset = 0

  # first, get rid of segment prefixes, if any
  set $_byte1 = *(unsigned char *)$rip
  # CALL DS:xx CS:xx, etc.
  if ($_byte1 == 0x3E || $_byte1 == 0x26 || $_byte1 == 0x2E || $_byte1 == 0x36 || $_byte1 == 0x3E || $_byte1 == 0x64 || $_byte1 == 0x65)
    set $lip = $rip + 1
    set $_byte1 = *(unsigned char*)$lip
    set $offset = 1
  end
  set $_byte2 = *(unsigned char *)($lip+1)
  set $_byte3 = *(unsigned char *)($lip+2)

  set $noffset = 0

  if ($_byte1 == 0xE8)
    # call near
    set $noffset = 3
  else
    if ($_byte1 == 0xFF)
      # A "ModR/M" byte follows
      set $_mod = ($_byte2 & 0xC0) >> 6
      set $_reg = ($_byte2 & 0x38) >> 3
      set $_rm  = ($_byte2 & 7)
      #printf "mod: %d reg: %d rm: %d\n", $_mod, $_reg, $_rm

      # only for CALL instructions
      if ($_reg == 2 || $_reg == 3)
	
	# default offset
	set $noffset = 2
	
	if ($_mod == 0)
	  if ($_rm == 6)
	    # a 16bit address follows
	    set $noffset = 4
	  end
	else
	  if ($_mod == 1)
	    # a 8bit displacement follows
	    set $noffset = 3
	  else
	    if ($_mod == 2)
	      # 16bit displacement
	      set $noffset = 4
	    end
	  end
	end
	
      end
      # end of _reg == 2 or _reg == 3

    else
      # else byte1 != 0xff
      if ($_byte1 == 0x9A)
	# call far
	set $noffset = 5
      else
	if ($_byte1 == 0xCD)
	  # INTERRUPT CASE
	  set $noffset = 2
	end
      end
    end
    # end of byte1 == 0xff
  end
  # else byte1 != 0xe8

  # if we have found a call to bypass we set a temporary breakpoint on next instruction and continue
  if ($noffset != 0)
    set $_nextaddress = $eip + $offset + $noffset
    printf "Setting BP to %04X\n", $_nextaddress
    tbreak *$_nextaddress
    continue
    # else we just single step
  else
    nexti
  end
end
document i86-stepo
Step over calls
This function will set a temporary breakpoint on next instruction after the call so the call will be bypassed
You can safely use it instead nexti since it will single step code if it's not a call instruction (unless you want to go into the call function)
end

define i86-step_until_iret
  set $SHOW_CONTEXT=0
  set $_found = 0
  while (!$_found)
    if (*(unsigned char*)$rip == 0xCF)
      set $_found = 1
    else
      stepo
    end
  end
  set $SHOW_CONTEXT=1
  i86-context
end

define i86-step_until_ret
  set $SHOW_CONTEXT=0
  set $_found = 0
  while (!$_found)
    set $_p = *(unsigned char*)$rip
    if ($_p == 0xC3 || $_p == 0xCB || $_p == 0xC2 || $_p == 0xCA)
      set $_found = 1
    else
      stepo
    end
  end
  set $SHOW_CONTEXT=1
  i86-context
end

define i86-step_until_int
  set $SHOW_CONTEXT = 0

  while (*(unsigned char*)$rip != 0xCD)
    stepo
  end
  set $SHOW_CONTEXT = 1
  i86-context
end

# Find a pattern in memory
# The pattern is given by a string as arg0
# If another argument is present it gives the starting address (0 otherwise)
define i86-find_in_mem
  if ($argc >= 2)
    set $_addr = $arg1
  else
    set $_addr = 0
  end
  set $_found = 0
  set $_tofind = $arg0
  while ($_addr < $ADDRESS_MASK) && (!$_found)
    if ($_addr % 0x100 == 0)
      printf "%08X\n", $_addr
    end
    set $_i = 0
    set $_found = 1
    while ($_tofind[$_i] != 0 && $_found == 1)
      set $_b = *((char*)$_addr + $_i)
      set $_t = (char)$_tofind[$_i]
      if ($_t != $_b)
	set $_found = 0
      end
      set $_i++
    end
    if ($_found == 1)
      printf "Code found at 0x%05X\n", $_addr
    end
    set $_addr++
  end
end
document i86-find_in_mem
 Find a pattern in memory
 The pattern is given by a string as arg0
 If another argument is present it gives the starting address (0 otherwise)
end


define i86-step_until_code
  set $_tofind = $arg0
  set $SHOW_CONTEXT = 0

  set $_found = 0
  while (!$_found)
    set $_i = 0
    set $_found = 1

    while ($_tofind[$_i] != 0 && $_found == 1)
      set $_b = *((char*)$rip + $_i)
      set $_t = (char)$_tofind[$_i]
      if ($_t != $_b)
	set $_found = 0
      end
      set $_i++
    end

    if ($_found == 0)
      stepo
    end
  end

  set $SHOW_CONTEXT = 1
  i86-context
end

