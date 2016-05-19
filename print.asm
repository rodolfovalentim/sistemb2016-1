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
	mov si, image

read:
 	mov ah, 3Fh
	mov bx, word[handle]
	mov cx, 1
	mov dx, input
	int 21h

	;verifica se o arquivo acabou	
	cmp ax, cx
	jl finishread
	
	;compara com o espaço
	mov dl, byte[input]
	cmp dl, 20h
	je store

	cmp dl, '0'
	jl finishread

	mov al, byte[buffer]
	sub dl, '0'
	mov bl, 0ah
	mul bl
	add al, dl
	mov byte[buffer], al
	jmp read
	
store:
	mov dl, byte[buffer]
	mov byte[si], dl
	inc si
	mov byte[buffer], 00h
	jmp read

finishread:
	; termina a leitura da imagem
	mov dl, [buffer]	
	mov byte[si], dl
	inc si
	mov byte[buffer], 00h
	jmp print

print:	
	;imprime a imagem na tela
	mov byte[si], '$'
	mov dx, image
	mov ah, 09h
	int 21h

doHistogram:
	mov si, image
	mov di, histogram
	mov cx, 62500
L2:
	mov bl, byte[si]
	add bx,bx
	add word[di+bx-1], 0001h
	inc si
	loop L2

acumulate:
	mov si, histogram
	mov di, cfd

	mov ax, [si]
	mov [di], ax
	add si, 2
	mov cx, 255
L3:
	mov ax, [si]
	add [di+2], ax
	mov ax, [di]
	add [di+2], ax
	add di, 2
	loop L3

exit:
	mov dx, histogram
	mov ah, 09h
	int 21h

	mov dx, cfd
	mov ah, 09h
	int 21h

	mov ah, 4Ch
	int 21h

segment data
filename	db	'teste.txt', 0
buffer		db	0
handle 		dw 	0
input		db	0
histogram:	times	256 dw 0
end1:		db	'A$'
cfd:		times	256 dw 0
end2:		db	'B$'
image:		resb  	62500

segment stack stack
resb 256
stacktop:

