;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; [6 steps] switch real-mode to protected-mode
; 
; 1. create segment Descriptor(Mint OS has only 2 segment in protected-mode)
; - code segment of protected-mode
; - data segment of protected mode
; 
; 2. Create GDT
; - store address of segment descriptor in the GDT
; - store size of segment descriptor in the GDT
; 
; 3. Set GDT information to Processor
; - store the address of GDT to GDTR register
; 
; 4. Setting CR0 Control register
; 
; 5. Change CS Segment Selector, and then jump into protected-mode using jmp Construction.
; - jmp 0x08(start address of protected-mode Kernel)
; - So far things happend in real-mode
; 
; 6. Initialize segment selector, and stack
; 
; * Start Protected-mode Kernel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


[ORG 0x00]		; set start address of code to 0x00
[BITS 16]

SECTION .text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CODE SECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	;start address of protected mode entry point : 0x10000
	mov ax, 0x1000  
	mov ds, ax
	mov es, ax

	cli				; prevent interrupt from occuring
	lgdt [GDTR]		; set "GDTR" data structure, and then load GDT Table

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Enter to Protected mode
	; - Disable Paging, cache, Internal FPU, Align Check
	; - Enable Protected mode
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, 0x4000003B	; PG=0, NW=0, AM=0, NE=1, ET=1
						; TS=1, EM=0, MP=1, PE(Protection Enable)=1

	mov cr0, eax		; switching to Portected Mode

	; set kernel code segment base to 0x00
	; set EIP value to 0x00
	; CS Segment Selector(0x08) : EIP
	jmp dword 0x08: ( PROTECTEDMODE - $$ + 0x10000)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Enter into Protected Mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
PROTECTEDMODE:
	mov ax, 0x10 		; Data Segment Descriptor of Protected Mode : 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	; set stack to address : 0x00000000~0x0000FFFF (64KB)
	mov ss, ax
	mov esp, 0xFFFE
	mov ebp, 0xFFFE

	push (SWITCHSUCCESSMESSAGE - $$ + 0x10000)
	push 2
	push 0
	call PRINTMESSAGE
	add esp, 12

	jmp $



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FUNCTION CODE SECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;PRINTMESSAGE(xPos, yPos, str)
PRINTMESSAGE:
	push	ebp
	mov		ebp, esp
	push	esi
	push	edi
	push	eax
	push	ecx
	push	edx

	;calc xPos address in video memory
	mov		eax, dword [ebp + 12]
	mov		esi, 160
	mul		esi
	mov		edi, eax

	;calc yPos address in video memory
	mov		eax, dword [ebp + 8]
	mov		esi, 2
	mul		esi
	add 	edi, eax

	;string address which you want to display
	mov		esi, dword [ebp + 16]



.MESSAGELOOP:
	mov cl, byte [esi]
	cmp cl, 0
	je .MESSAGEEND

	mov byte [edi + 0xb8000], cl
	add esi, 1
	add edi, 2
	jmp .MESSAGELOOP

.MESSAGEEND:
	pop edx
	pop ecx
	pop eax
	pop edi
	pop esi
	pop ebp
	ret




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DATA SECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
align 8, db 0

dw 0x0000
GDTR:
	dw GDTEND - GDT - 1
	dd (GDT - $$ + 0x10000)

GDT:
	NULLDESCRIPTOR:
		dw 0x0000 	
		dw 0x0000 	
		db 0x00 	
		db 0x00 	
		db 0x00 	
		db 0x00 	

	CODEDESCRIPTOR:
		dw 0xFFFF 	;Limit
		dw 0x0000 	;Base
		db 0x00 	;Base
		db 0x9A 	;P=1, DPL=0, Code Segment, Execute/Read
		db 0xCF 	;G=1, D=1, L=0, Limit
		db 0x00 	;Base

	DATADESCRIPTOR:
		dw 0xFFFF 	;Limit
		dw 0x0000 	;Base
		db 0x00 	;Base
		db 0x92 	;P=1, DPL=0, Data Segment, Read/Write
		db 0xCF 	;G=1, D=1, L=0, Limit
		db 0x00 	;Base
GDTEND:

SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success~!!', 0

times 512 - ($ - $$) db 0x00









