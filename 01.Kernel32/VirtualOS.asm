[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x1000:START

SECTORCOUNT:	dw 0x0000

START:
	mov ax, cs
	mov ds, ax
	mov ax, 0xB800
	mov es, ax

	mov ax, 2
	mul word [SECTORCOUNT]
	mov si, ax
	mov byte [es:si + (160 * 2)], '0'
	add word [SECTORCOUNT], 1

	jmp $

	times 512 -($ - $$) db 0x00