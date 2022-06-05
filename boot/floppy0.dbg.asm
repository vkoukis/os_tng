	bits 16

	jmp short start	; Jump over the data (the 'short' keyword makes the jmp instruction smaller)

msg:
	db "Hello World! "
endmsg:

start:
	mov bx, 000Fh	; Page 0, colour attribute 15 (white) for the int 10 calls below
	mov cx, 1	; We will want to write 1 character
	xor dx, dx	; Start at top left corner
	mov ds, dx	; Ensure ds = 0 (to let us load the message)
	mov dh, 23      ; Actually, no: Start at the bottom
	cld		; Ensure direction flag is cleared (for LODSB)

print:
	mov si, msg	; Loads the address of the first byte of the message, 7C02h in this case

			; PC BIOS Interrupt 10 Subfunction 2 - Set cursor position
			; AH = 2
char:
	mov ah, 2	; BH = page, DH = row, DL = column
	int 10h
	lodsb		; Load a byte of the message into AL.
			; Remember that DS is 0 and SI holds the
			; offset of one of the bytes of the message.

			; PC BIOS Interrupt 10 Subfunction 9 - Write character and color
			; AH = 9
	mov ah, 9	; BH = page, AL = character, BL = attribute, CX = character count
	int 10h

	inc dl		; Advance cursor

	cmp dl, 80	; Wrap around edge of screen if necessary
	jne skip
	xor dl, dl
	inc dh

	cmp dh, 25	; Wrap around bottom of screen if necessary
	jne skip
	xor dh, dh

skip:
	cmp si, endmsg	; If we're not at end of message,
	jne char	; continue loading characters
	jmp print	; Otherwise restart from the beginning of the message

	times 0200h - 2 - ($ - $$) \
	db 0		; Zerofill up to 510 bytes [+2 bytes signature = 512 bytes, a full sector]

	dw 0AA55h	; Boot Sector signature

; OPTIONAL:
; To zerofill up to the size of a standard 1.44MB, 3.5" floppy disk
; times 1474560 - ($ - $$) db 0
