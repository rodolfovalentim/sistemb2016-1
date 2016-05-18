segment code
..start:
	mov ax, data
	mov ds, ax
	mov ax, stack
	mov ss,	ax
	mov sp, stacktop

equalize:
	mov si, histogram
	mov di, eqhistogram
	mov ax, [si]
	mov [di], ax
	add si, 2
	mov cx, 9
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
histogram:	times	10 dw 0001h
eqhistogram:	times	10 dw 0000h
fim1		db	'$'

segment stack stack
	resb 256
stacktop:
