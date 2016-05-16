segment code
..start
	mov ax, data
	mov ds, ax
	mov ax, stack
	mov ss,	ax
	mov sp, stacktop
	
	;abre arquivo
	mov ah, 3Dh
	mov al, 00
	mov dx, filename
	mov cx, 1
	int 21h	

	mov [handle], ax
	;mov bx, buffer
	;mov [pointer], bx
le:
 	mov ah, 3Fh
	mov bx, [handle]
	mov cx, 1
	mov dx, input
	int 21h

	;compara com o espaço
	mov dl, [input]
	cmp dl, 20h
	je exit

	mov bx, buffer
	mov dl, [input]
	mov byte[bx], dl
	add bx, 1
	mov byte[bx], 24h 	

	mov dx, buffer
	mov ah, 09h
	int 21h
	jmp le
exit:
	mov ah, 4Ch
	int 21h
	
segment data
filename	db	'teste.txt', 0
buffer		db	'a', 24h
input		db	42h
handle:		resw 	1
pointer:	resw 	1

segment stack stack
	resb 256
stacktop:
