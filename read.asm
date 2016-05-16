segment code
..start
	mov ax, data
	mov ds, ax
	mov ax, stack
	mov ss,	ax
	mov sp, stacktop

le:	mov ah, 3Fh
	mov bx, handle
	mov cx, 1
	mov dx, input
	int 21h

	;escreve no console
	mov dl, [input]
	cmp dl, 20h
	je exit
	
	mov ah, 09h
	mov dx, buffer
	int 21h
	jmp le

exit
	mov ah, 4Ch
	int 21h
	
segment data
filename	db	'teste.txt', 0
buffer		db	00,00,00,'$'
input		db	00
handle:	resw 1

segment stack stack
	resb 256
stacktop:
