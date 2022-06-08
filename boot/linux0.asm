		global _start

		section .text

msg:		db "Hello, World!", 0x0a
msglen:		equ $ - msg

_start:		mov eax, 4	; sys_write
		mov ebx, 1	; three arguments for write(2)
		mov ecx, msg
		mov edx, msglen
		int 80h

		;mov esi, msg
		;mov byte [esi], 65

		;in al, 70h
		;cli
		;hlt

		mov eax, 1	; sys_exit
		xor ebx, ebx	; exit code is zero
		int 80h
