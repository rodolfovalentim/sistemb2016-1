segment code
..start:
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

	mov word[handle], ax
	mov bx, image
	mov word[pointer], bx
read:
 	mov ah, 3Fh
	mov bx, word[handle]
	mov cx, 1
	mov dx, input
	int 21h
	
	cmp ax, cx
	jl finishread
	
	;compara com o espaço
	mov dl, byte[input]
	cmp dl, 20h
	je store
	mov al, byte[buffer]
	sub dl, '0'
	mov bl, 0ah
	mul bl
	add al, dl
	mov bx, buffer
	mov byte[bx], al
	jmp read
	
store:
	mov bx, word[pointer]
	mov dl, byte[buffer]
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
	mov bx, word[pointer]
	mov byte[bx], '$'
	mov word[pointer], bx
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
handle		dw 	0
pointer		dw 	1
image:		resb  62500

segment stack stack
	resb 256
stacktop:

