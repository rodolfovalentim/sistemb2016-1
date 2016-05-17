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
	mov bx, image
	mov [pointer], bx
read:
 	mov ah, 3Fh
	mov bx, [handle]
	mov cx, 1
	mov dx, input
	int 21h

	;compara com o espaço
	mov dl, [input]
	cmp dl, 20h
	je store
	cmp ax, cx
	jl finishread
	mov al, [buffer]
	sub dl, '0'
	cmp dl, 0
	jl finishread
	mov bl, 0ah
	mul bl
	add al, dl
	mov bx, buffer
	mov byte[bx], al
	jmp read
	
store:
	mov bx, [pointer]
	mov dl, [buffer]
	mov byte[bx], dl
	mov [pointer], bx
	inc word[pointer]
	mov bx, buffer
	mov byte[bx], 00h
	jmp read

finishread:
	mov bx, [pointer]
	mov dl, [buffer]
	mov byte[bx], dl
	mov [pointer], bx
	inc word[pointer]
	mov bx, buffer
	mov byte[bx], 00h
	jmp print	

print:
	mov bx, [pointer]
	mov byte[bx], '$'
	mov [pointer], bx
	mov dx, image
	mov ah, 09h
	int 21h
	
exit:
	mov ah, 4Ch
	int 21h
	
segment data
filename	db	'imagem.txt', 0
buffer		db	0
input		db	0
handle:		resw 	1
pointer		dw 	1
image		resb  62500
samples		dw	0

segment stack stack
	resb 256
stacktop:
