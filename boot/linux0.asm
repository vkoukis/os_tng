		global _start

		section .text

msg:		db "Hello, World!", 0x0a
msglen:		equ $ - msg

_start:		mov eax, 4
		mov ebx, 1
		mov ecx, msg
		mov edx, msglen
		int 80h

		;mov esi, msg
		;mov byte [esi], 65

		;in al, 70h
		;cli

		mov eax, 1
		int 80h
