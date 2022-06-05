        org 7C00h

VGA_SEG:	equ 0b800h	; VGA memory-mapped framebuffer lives at B800:0000
VGA_WIDTH:	equ 80		; We assume 80x25 text mode
VGA_HEIGHT:	equ 25
PARPORT:	equ 378h

	jmp short start	; Jump over the data (the 'short' keyword makes the jmp instruction smaller)

msg:
	db "Hello World! "
endmsg:
msglen:	equ $-msg

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

	cmp dl, VGA_WIDTH	; Wrap around edge of screen if necessary
	jne skip
	xor dl, dl
	inc dh

	cmp dh, VGA_HEIGHT	; Wrap around bottom of screen if necessary
	jne skip
	xor dh, dh

skip:
	cmp si, endmsg	; If we're not at end of message,
	jne char	; continue loading characters

parmsg:			; Output the message to the first parallel port
			; [we assume the BIOS has already initialized it]

	mov si, msg
	mov cx, msglen	; By looping over the characters
parchar:
	mov dx, PARPORT	; Data [base port]
	lodsb		; Fetch byte from DS:[SI] into AL
	out dx,al	; Output character as data

	mov dx, PARPORT + 2	; Control [base port + 2]
	in al, dx	; Fetch control byte
	or al, 1	; Set the LSB [Signal Strobe low]
	out dx,al	; Output control byte

			; We have to keep Strobe low for at least 0.5us
			; let's wait for a little while
	push cx
	mov cx, 1000
wait0:
	push cx
	mov cx, 0FFFFh
wait1:
	loop wait1
	pop cx
	loop wait0
	pop cx

	in al, dx	; Fetch control byte
	and al, 0xfe	; Clear the LSB [Signal Strobe high]
	out dx,al	; Output control byte

	loop parchar	; Move to next character

biospar:		; Output one extra exclamation mark using the BIOS
	xor ah,ah	; AH = 00h
	mov al,'!'	; AL = character to write
	xor dx,dx	; DX = printer number (00h-02h)
	int 17h		; Do it!

vgamsg:			; Output the message to the VGA framebuffer directly

	mov ax, VGA_SEG
	mov es, ax
	mov si, msg
	mov cx, msglen

	mov ah, 0fh	; AH = color attribute: Background: black, foreground: white.
	mov dh, 15	; DH = row
	mov dl, 20	; DL = column

vgachar:		; Output one character to the VGA console
			; accessing the VGA MMIO space directly
	lodsb		; Fetch byte from DS:[SI] into AL
			; AL = char, AH = color attr, DH = row, DL = col
			; Compute the location in the framebuffer into AX:
			; AX = (DH * VGA_WIDTH + DL) * 2 [each cell is a 16-bit word]
	mov di, ax	; Use DI as a temporary location for AX
	mov al, dh	;  ...this would be a 32-bit LEA and an ADD
	mov ah, VGA_WIDTH
	mul ah		; AX = DH * VGA_WIDTH
	mov bh, dh	; Use BH as a temporary location for DH
	xor dh, dh	; so we can zero it out
	add ax, dx	; AX = DH * VGA_WIDTH + DL
	mov dh, bh	; restore DH
	shl ax, 1	; AX = (DH * VGA_WIDTH + DL) * 2
	xchg di, ax
	mov [es:di], ax	; Move both the color attribute and the character value
			; as a single 16-bit word into the framebuffer

	inc dl		; Advance cursor

	cmp dl, VGA_WIDTH ; Wrap around edge of screen if necessary
	jne skip2
	xor dl, dl
	inc dh

	cmp dh, VGA_HEIGHT	; Wrap around bottom of screen if necessary
	jne skip2
	xor dh, dh

skip2:
	loop vgachar

l1:
	jmp l1

	times 0200h - 2 - ($ - $$) \
	db 0		; Zerofill up to 510 bytes [+2 bytes signature = 512 bytes, a full sector]

	dw 0AA55h	; Boot Sector signature

; OPTIONAL:
; To zerofill up to the size of a standard 1.44MB, 3.5" floppy disk
; times 1474560 - ($ - $$) db 0
