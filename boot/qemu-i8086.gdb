target remote localhost:1234
set tdesc filename i8086.xml
set architecture i8086
set disassembly-flavor intel

# Also enable our i8086 helpers
source i8086.gdb
