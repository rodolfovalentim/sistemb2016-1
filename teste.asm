segment code
..start:
	mov ax, data
	mov ds, ax
	mov ax, stack
	mov ss,	ax
	mov sp, stacktop
	
	mov dx, histogram
	mov ah, 09h
	int 21h
	jmp exit

exit:
	mov ah, 4Ch
	int 21h

segment data
histogram:	times	256 db 'a'
fim1		db	'$'

segment stack stack
	resb 256
stacktop:

