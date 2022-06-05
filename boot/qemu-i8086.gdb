target remote localhost:1234
set tdesc filename i8086.xml
set architecture i8086
set disassembly-flavor intel

define xi
	x/20i $cs*16+$eip
end
