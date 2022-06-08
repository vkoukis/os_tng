		global _start

		section .text

sys_exit:	equ 1
sys_write:	equ 4
sys_sigaction:	equ 67
SIGSEGV:	equ 11

msg:		db "Hello, World!", 0x0a
msglen:		equ $ - msg

err:		db "I just received a SIGSEGV. Continuing happily.", 0x0a
errlen:		equ $ - err

handle_sigsegv:	mov eax, sys_write
		mov ebx, 1
		mov ecx, err
		mov edx, errlen
		int 80h			; Let's use write(2) to print a message

		ret

sigaction:				; struct sigaction {
		dd handle_sigsegv	;	void (*sa_handler)(int);
		; Omitted, union	;	void (*sa_sigaction)(int, siginfo_t *, void *);
		times 128 db 0 		;	sigset_t sa_mask;
		dd 0			;	int sa_flags;
		; Not for app use 	;	void (*sa_restorer)(void);
					; };
_start:		mov eax, sys_write	; sys_write
		mov ebx, 1		; file descriptor
		mov ecx, msg		; buffer
		mov edx, msglen		; length
		int 80h			; Use syscall instead? Note syscall numbers are different!

		; The actual signal(2) system call is obsolete.
		; See the manpage, not even the signal() libC wrapper calls it.
		; Use sigaction(2) instead.

		mov eax, sys_sigaction	; sys_sigaction
		mov ebx, SIGSEGV	; SIGSEGV
		mov ecx, sigaction	; pointer to struct sigaction *act
		xor edx, edx		; we don't need the old sigaction struct, pass NULL
		int 80h			; Do it!

		;mov esi, msg		; let's attempt a write to this string
		;mov byte [esi], 65	; write a single byte, attempt to overwrite 'H' with 'A'

		in al, 70h
		;cli

		mov eax, sys_exit
		int 80h


