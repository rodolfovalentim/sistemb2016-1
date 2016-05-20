segment code
..start:
    	mov 	ax,data
    	mov 	ds,ax
    	mov 	ax,stack
    	mov 	ss,ax
    	mov 	sp,stacktop

	; salvar modo corrente de video(vendo como esta o modo de video da maquina)
        mov 	ah, 0Fh
    	int 	10h
    	mov 	[modo_anterior], al   

	; alterar modo de video para grafico 640x480 16 cores
    	mov    	al, 12h
   	mov    	ah, 0
    	int    	10h

	mov ax, 15h
	int 33h

	mov ax, 16h
	mov [size_mouse], bx
	mov dx, status_mouse
	int 33h

	mov ax,0
	int 33h ; mouse interrupt
	; (ifi AX=FFFFh mouse is installed, if 0000 not, DX - number of mouse buttons)

	cmp ax,0
	ja pmouse ; if AX > 0 lets start!

	mov ax, 01
	int 33h
	jmp pmouse

	mov ah,4ch
	int 21h ;else just exit

pmouse:

	mov ax,03 ; function to get mouse position and buttons 
	int 33h

	mov ax,dx ; Y coord to AX
	mov dx,320

	mul dx ; multiply AX by 320
	add ax,cx ; add X coord

	; (Now currsor position is in AX, lets draw the pixel there)

	mov di,ax
	mov ax,0A000h
	mov es,ax
	mov dl,12 ; red color ;)
	mov [di],dl ; and we have the pixel drawn

	;By default mouse resolution is 640x200, lets set it to c (monitor height is already set, lets just set the width)

	mov ax, 7 
	mov cx,0 ; min pos 
	mov dx,320 ; max pos 
	int 33h

	;And height can be set:

	mov ax, 8
	mov cx,0
	mov dx,200
	int 33h

segment data
modo_anterior	db		0
status_mouse	dw		0
size_mouse	dw		0

segment stack stack
	resb 256
stacktop:
