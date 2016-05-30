%macro drawline 5 		;x1,y1,x2,y2,color
	mov	ax,%1
	push	ax
	mov	ax,%2
	push	ax
	mov	ax,%3
	push	ax
	mov	ax,%4
	push	ax
	mov	byte[cor],%5
	call	line
%endmacro

%macro ponto 2				; x,y,color
	add 	%1, 3
	add 	%2, 100
	push 	%1
	push 	%2	
	call	plot_xy
	sub	%1, 3
	sub 	%2, 100
%endmacro

%macro writeword 4
	mov	byte[cor], %4
    	mov     bx,0
    	mov     dh,%2			;linha 0-29
    	mov     dl,%3			;coluna 0-79
%%local:
	call	cursor
    	mov     al,[bx+%1]
	cmp	al, '$'
	je	%%exit
	call	caracter
    	inc     bx			;proximo caracter
	inc	dl			;avanca a coluna
    	jmp	%%local
%%exit:
%endmacro

%macro write318 2 ; motor, led
	pusha
	mov 	al, %1
	mov 	cl, %2
	shl 	al, 6
	or	al, cl
	mov 	dx, 318h
	out 	dx, al
	popa
%endmacro

%macro write319 1
	pusha
	mov 	al, 0
	or 	al, %1	
	mov 	dx, 319h
	out 	dx, al
	popa
%endmacro

%macro read319 0
	mov 	al, 80h
	mov 	dx, 319h
	in	al, dx
	mov	ah, al
	and 	al, 00111111b
	shr	ah, 6
	and 	ah, 1b
%endmacro

segment code
..start:
	mov ax, data
	mov ds, ax 
	mov ax, stack
	mov ss,	ax
	mov sp, stacktop
	
	; setup 318h to write
	mov 	ax, 0
	mov 	dx, 319h
	out 	dx, al

	write318 10b, 00h	; go to last floor
	mov 	 ax, 2000	; counter to delay
	call 	 DELAY		; call delay
	write318 01b, 00h	; stop and wait for instructions

ETERNO:
	read319
	mov bx, state_sensor
	cmp byte[bx], 0
	je SENSOR0
	cmp ah, 0
	je DEBOUNCE
	jmp ETERNO
SENSOR0:
	cmp ah, 1
	je DEBOUNCE
	jmp ETERNO	

DEBOUNCE:
	mov 	 bh, ah 
	mov 	 ax, 10
	call 	 DELAY
	read319
	cmp ah, bh
	je HANDLE_CHANGE
	jmp ETERNO

HANDLE_CHANGE:
	mov [state_sensor], ah
	cmp ah, 0
	je HANDLE_FLOOR
	jmp ETERNO

HANDLE_FLOOR:
	mov al, byte[floor]
	dec al
	mov byte[floor], al
	cmp al, 2
	je EXIT
	jmp ETERNO

EXIT:
	write318 00b, 00h
	mov 	ah, 4Ch
	int	21h

DELAY:
	mov 	cx, ax
DELAY2:
	push 	cx
	mov 	cx, 0
DELAY1:
	loop 	DELAY1
	pop 	cx
	loop 	DELAY2
	ret

;***************************************************************************
; função cursor
; dh = linha (0-29) e  dl=coluna  (0-79)
;***************************************************************************
cursor:
	pushf
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov    	ah,2
	mov    	bh,0
	int    	10h
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
;_____________________________________________________________________________
;
;   fun��o caracter escrito na posi��o do cursor
;
; al= caracter a ser escrito
; cor definida na variavel cor
caracter:
	pushf
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
    	mov    	ah,9
    	mov    	bh,0
    	mov    	cx,1
   	mov    	bl,[cor]
    	int    	10h
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf
	ret
;_____________________________________________________________________________
;
;   função plot_xy
;
; push x; push y; call plot_xy;  (x<639, y<479)
; cor definida na variavel cor
plot_xy:
	push	bp
	mov	bp,sp
	pushf
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	mov    	ah,0ch
	mov    	al,[cor]
	mov    	bh,0
	mov    	dx,479
	sub	dx,[bp+4]
	mov    	cx,[bp+6]
	int    	10h
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	popf
	pop	bp
	ret	4
;-----------------------------------------------------------------------------
;
;   fun��o line
;
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
	push	bp
	mov	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	mov	ax,[bp+10]   ; resgata os valores das coordenadas
	mov	bx,[bp+8]    ; resgata os valores das coordenadas
	mov	cx,[bp+6]    ; resgata os valores das coordenadas
	mov	dx,[bp+4]    ; resgata os valores das coordenadas
	cmp	ax,cx
	je	line2
	jb	line1
	xchg	ax,cx
	xchg	bx,dx
	jmp	line1
line2:		
	; deltax=0
	cmp	bx,dx  ;subtrai dx de bx
	jb	line3
	xchg	bx,dx        ;troca os valores de bx e dx entre eles
line3:	
	; dx > bx
	push 	ax
	push	bx
	call	plot_xy
	cmp	bx,dx
	jne	line31
	jmp	fim_line
line31:	inc	bx
	jmp	line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
; cx > ax
	push	cx
	sub	cx,ax
	mov	[deltax],cx
	pop	cx
	push	dx
	sub	dx,bx
	ja	line32
	neg	dx
line32:		
	mov	[deltay],dx
	pop	dx

	push	ax
	mov	ax,[deltax]
	cmp	ax,[deltay]
	pop	ax
	jb	line5

; cx > ax e deltax>deltay
	push	cx
	sub	cx,ax
	mov	[deltax],cx
	pop	cx
	push	dx
	sub	dx,bx
	mov	[deltay],dx
	pop	dx

	mov	si,ax
line4:
	push	ax
	push	dx
	push	si
	sub	si,ax	;(x-x1)
	mov	ax,[deltay]
	imul	si
	mov	si,[deltax]		;arredondar
	shr	si,1
; se numerador (DX)>0 soma se <0 subtrai
	cmp	dx,0
	jl	ar1
	add	ax,si
	adc	dx,0
	jmp	arc1
ar1:		
	sub	ax,si
	sbb	dx,0
arc1:
	idiv	word [deltax]
	add	ax,bx
	pop	si
	push	si
	push	ax
	call	plot_xy
	pop	dx
	pop	ax
	cmp	si,cx
	je	fim_line
	inc	si
	jmp	line4

line5:		
	cmp	bx,dx
	jb 	line7
	xchg	ax,cx
	xchg	bx,dx
line7:
	push 	cx
	sub 	cx,ax
	mov  	[deltax],cx
	pop  	cx
	push 	dx
	sub 	dx,bx
	mov 	[deltay],dx
	pop 	dx
	mov 	si,bx
line6:
	push 	dx
	push 	si
	push 	ax
	sub  	si,bx	;(y-y1)
	mov  	ax,[deltax]
	imul 	si
	mov  	si,[deltay]		;arredondar
	shr  	si,1
	; se numerador (DX)>0 soma se <0 subtrai
	cmp  	dx,0
	jl   	ar2
	add  	ax,si
	adc  	dx,0
	jmp  	arc2
ar2:	
	sub 	ax, si
	sbb 	dx, 0
arc2:
	idiv 	word [deltay]
	mov 	di, ax
	pop 	ax
	add 	di, ax
	pop 	si
	push 	di
	push 	si
	call 	plot_xy
	pop 	dx
	cmp 	si, dx
	je  	fim_line
	inc 	si
	jmp 	line6

fim_line:
	pop	di
	pop 	si
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	popf
	pop 	bp
	ret 	8

;*******************************************************************
segment data

cor      	db		branco_intenso
preto		equ		0
azul		equ		1
verde		equ		2
cyan		equ		3
vermelho	equ		4
magenta		equ		5
marrom		equ		6
branco		equ		7
cinza		equ		8
azul_claro	equ		9
verde_claro	equ		10
cyan_claro	equ		11
rosa		equ		12
magenta_claro	equ		13
amarelo		equ		14
branco_intenso	equ		15
modo_anterior	db		0
linha   	dw  		0
coluna  	dw  		0
deltax		dw		0
deltay		dw		0
abrir    	db  		'ABRIR$'
sair    	db  		'SAIR$'
state_led	db		0
state_motor	db		0
requests	db		0
floor		db		4
state_sensor	db		1

segment stack stack
	resb 256
stacktop:
