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
	mov byte[buffer], al
	jmp read
	
store:
	mov bx, word[pointer]
	mov dl, byte[buffer]
	mov byte[bx], dl
	mov [pointer], bx
	inc word[pointer]
	mov byte[buffer], 00h
	jmp read

finishread:
	mov bx, [pointer]
	mov dl, [buffer]
	mov byte[bx], dl
	mov [pointer], bx
	inc word[pointer]
	mov byte[buffer], 00h
	jmp print	

print:
	mov bx, word[pointer]
	mov byte[bx], '$'
	mov word[pointer], bx
	mov dx, image
	mov ah, 09h
	int 21h
	jmp cphist

cphist:
	mov bx, histogram
	mov word[pointer], bx
	mov cx, 10
prox:
	mov ah, 00h
	mov al, byte[image] 
	mov si, ax
	mov byte[bx+si], al
	inc word[image]
	loop prox
	
printh:
	mov dx, histogram
	mov ah, 09h
	int 21h
	jmp exit

exit:
	mov ah, 4Ch
	int 21h

segment data
filename	db	'imagem.txt', 0
buffer		db	0
input		db	0
handle		dw 	0
pointer		dw 	1
histogram:	times	256 db '0'
fim1		db	'$'
image:		resb  	62500

segment stack stack
	resb 256
stacktop:

