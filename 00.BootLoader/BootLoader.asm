[ORG 0x00]			; Set code's start address to 0x00
[BITS 16]			; The following code is set to 16 bits

SECTION .text		
jmp 0x07C0:START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; environment setting for MINT64 OS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT:	dw	1024



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	mov ax, 0x07C0
	mov ds, ax

	mov ax, 0xB800
	mov es, ax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; initialize Stack with 64KB size
	; 0x0000:0000-0x0000:FFFF
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ax, 0x0000
	mov ss, ax
	mov sp, 0xFFFE
	mov bp, 0xFFFE

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Clear screen & set attribute value to green
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov si, 0

.SCREENCLEARLOOP:
	mov byte [es:si], 0
	mov byte [es:si+1], 0x0A ; 0x0A => BLACK & GREEN

	add si, 2
	cmp si, 80 * 25 * 2
	jl .SCREENCLEARLOOP


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Print message at the top of the screen
	; PRINTMESSAGE(xPox, yPos, Message)
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push MESSAGE1	; target message
	push 0			; screen Y pos
	push 0			; screen X pos
	call PRINTMESSAGE
	add sp, 6		; 6 = 2(parm size) * 3

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Print loading message at the screen
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push IMAGELOADINGMESSAGE
	push 1
	push 0
	call PRINTMESSAGE
	add sp, 6


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; LOAD OS IMAGE FROM DISK
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Reset disk before read
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Call BIOS Reset Function
	; - int 0x13 : BIOS DISK I/O Service interrupt number
	; - ah = 0x00  => ax = 0 : Reset Disk
	; disk type : (0x00: Floppy, 0x80: Fisrt Hard Disk, 0x81: Second Hard Disk)
	; - dl = 0x00
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ax, 0
	mov dl, 0
	int 0x13
	; jump to error handling, if error occured!
	jc HANDLEDISKERROR

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Read sector at disk (READ : disk -> memory(0x10000))
	; ES : 0x1000
	; BX : 0x0000
	; physical address : ES * 0x10 + BX : 0x100000
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov si, 0x1000
	mov es, si
	mov bx, 0x0000

	mov di, word [ TOTALSECTORCOUNT ]
READDATA:
	cmp di, 0
	je READEND
	sub di, 0x01

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; call BIOS Read Function
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ah, 0x02				; read sector function's bios service number : 0x02
	mov al, 0x1 				; set the number of sector to read
	mov ch, byte [TRACKNUMBER]	; set the tarck number to read
	mov cl, byte [SECTORNUMBER]	; set the sector number to read
	mov dh, byte [HEADNUMBER]	; set drive number to read(0=FLOPPY)
	int 0x13
	jc HANDLEDISKERROR

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; calculate address to copy, track, head, sector
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	add si, 0x0020		;conver read count 512(0x200) to segment register value
	mov es, si

	mov al, byte [SECTORNUMBER]
	add al, 0x01
	mov byte[SECTORNUMBER], al
	cmp al, 19
	jl READDATA

	;if you read end of sector, toggle head.
	;and then set sector to 1
	xor byte [HEADNUMBER], 0x01
	mov byte [SECTORNUMBER], 0x01

	cmp byte [HEADNUMBER], 0x00
	jne READDATA

	add byte [TRACKNUMBER], 0x01
	jmp READDATA
READEND:

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Print message about OS image loading complete!
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push LOADINGCOMPLETEMESSAGE
	push 1
	push 20
	call PRINTMESSAGE
	add sp, 6

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; execute loaded virtual OS image
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp 0x1000:0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function code area
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HANDLEDISKERROR:
	push DISKERRORMESSAGE
	push 1
	push 20
	call PRINTMESSAGE
	jmp $

PRINTMESSAGE:
	push bp
	mov  bp, sp

	push es
	push si
	push di
	push ax
	push cx
	push dx

	mov ax, 0xB800
	mov es, ax

	mov ax, word [bp  + 6]
	mov si, 160
	mul si
	mov di, ax

	mov ax, word [bp + 4]
	mov si, 2
	mul si
	add di, ax

	mov si, word [bp + 8]

.MESSAGELOOP:
	mov cl, byte [si]
	cmp cl, 0
	je .MESSAGEEND

	mov byte[es:di], cl
	
	add si, 1
	add di, 2

	jmp .MESSAGELOOP

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Data Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MESSAGE1:				db	'MINT64 OS Boot Loader Start~!!', 0
DISKERRORMESSAGE:		db	'DISK Error~!!', 0
IMAGELOADINGMESSAGE:	db	'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE:	db	'Complete~!!', 0

SECTORNUMBER:			db	0x02
HEADNUMBER:				db	0x00
TRACKNUMBER:			db	0x00

times 510 - ($ - $$) db 0x00
;$			: address of this line
;$$			: start address of this section(.text)
;time n sth : repeat sth n times


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mark boot sector
; address 511 => 0x55
; address 512 => 0xAA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0x55
db 0xAA
