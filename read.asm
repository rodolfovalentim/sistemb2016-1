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
	
					;verifica se o arquivo acabou	
	cmp ax, cx
	jl finishread
	
					;compara com o espaço
	mov dl, byte[input]
	cmp dl, 20h
	je store

	cmp dl, '0'
	jl read

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

finishread: 				; termina a leitura da imagem
	mov bx, [pointer]
	mov dl, [buffer]
	mov byte[bx], dl
	mov [pointer], bx
	inc word[pointer]
	mov byte[buffer], 00h
	jmp print	

print:					;imprime a imagem na tela
	mov bx, word[pointer]
	mov byte[bx], '$'
	mov word[pointer], bx
	mov dx, image
	mov ah, 09h
	int 21h
	jmp cphist

cphist: 				; computa histograma
	mov bx, image
	mov cx, 1
prox:
	mov ah, 00h
	mov al, byte[bx] 
	mov si, ax
	add si, si
	add word[histogram+si], 1
	add bx, 1 			;anda na imagem
	loop prox

printh: 				;imprime histograma obtido
	mov dx, histogram
	mov ah, 09h
	int 21h
	int 3

equalize:
	mov si, histogram
	mov di, eqhistogram
	mov ax, [si]
	mov [di], ax
	add si, 2
	mov cx, 255
.iter:
	mov ax, [si]
	add [di+2], ax
	mov ax, [di]
	add [di+2], ax
	add di, 2
	loop .iter

exit:
	mov ah, 4Ch
	int 21h

segment data
filename	db	'teste.txt', 0
buffer		db	0
input		db	0
handle		dw 	0
pointer		dw 	1
histogram:	times	256 dw 0000h
eqhistogram:	times	256 dw 0000h
fim1		db	'$'
image:		resb  	1

segment stack stack
	resb 256
stacktop:

