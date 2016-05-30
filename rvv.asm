; Rodolfo Vieira Valentim
; Sistemas Embarcados 2016/1

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

;*******************************************************************

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
	
	drawline 255, 0, 255, 479, branco_intenso
	drawline 255, 239, 639, 239, branco_intenso
	drawline 63, 479, 63, 431, branco_intenso
	drawline 127, 479, 127, 431, branco_intenso
	drawline 191, 479, 191, 431, branco_intenso
	drawline 0, 431, 255, 431, branco_intenso
	drawline 0, 63, 255, 63, branco_intenso

	writeword abrir, 1, 1, branco_intenso
	writeword sair, 1, 10, branco_intenso
	writeword hist, 1, 18, branco_intenso
	writeword eqhist, 1, 25, branco_intenso
	writeword txhist, 1, 33, branco_intenso
	writeword txeqhist, 16, 33, branco_intenso
	writeword nome, 27, 1, branco_intenso
	writeword disc, 28, 1, branco_intenso

	mov 	ax, 01h
	int 	33h		
ETERNO:
	mov 	ax, 05h
	mov 	bx, 0
	int 	33h

	test 	bl, 1
	jz 	ETERNO
	jmp 	LEFT_BUTTON_PRESSED

EXIT:
	mov 	ah,0   			; set video mode
	mov 	al,[modo_anterior]   	; modo anterior
	int 	10h

	mov 	ah, 4Ch
	int	21h

;*******************Functions***************************************

OPEN:
	mov 	byte[flaghist], 0
	mov 	byte[flageqhist], 0
	mov 	bx, cfd
	mov 	di, histogram
	mov 	si, eqhistogram
	mov 	ax, 319
	mov 	dx, 319
	mov 	cx, 256
RESETH:
	mov 	word[bx], 00
	mov 	word[di], 00
	mov 	word[si], 00
	add 	di, 2
	add 	si, 2
	add 	bx, 2
	pusha
	drawline ax, 16, dx, 207, preto
	popa
	pusha
	drawline ax, 250, dx, 447, preto
	popa	
	inc 	ax
	inc 	dx
	loop 	RESETH	

	;abre arquivo
	mov 	ah, 3Dh
	mov	al, 00
	mov 	dx, filename
	mov 	cx, 1
	int 	21h	

	mov 	word[handle], ax
	mov 	si, image

READ:
 	mov 	ah, 3Fh
	mov 	bx, word[handle]
	mov	cx, 1
	mov 	dx, input
	int	21h

	;verifica se o arquivo acabou	
	cmp 	ax, cx
	jl 	FINISH_READ
	
	;compara com o espaço
	mov 	dl, byte[input]
	cmp 	dl, 20h
	je 	STORE

	mov 	al, byte[buffer]
	sub 	dl, '0'
	mov 	bl, 0ah
	mul 	bl
	add 	al, dl
	mov 	byte[buffer], al
	jmp 	READ
	
STORE:
	mov 	dl, byte[buffer]
	mov 	byte[si], dl
	inc 	si
	mov 	byte[buffer], 00h
	jmp	READ

FINISH_READ:
	; termina a leitura da imagem
	mov 	dl, [buffer]	
	mov 	byte[si], dl

	mov ah, 3Eh
	int 21h

PRINT:	
	; print to screen
	mov 	si, 0  	; x
	mov 	di, 249	; y
	mov 	bx, image

L3:	cmp 	di, 0
	je 	EL3
	mov 	ah, 00h
	mov 	al, byte[bx]
	shr 	al, 4
	mov 	byte[cor], al	
	ponto 	si, di
	inc 	si
	inc 	bx	
	cmp 	si, 250
	je 	RCAX
	jmp 	L3
RCAX:	
	;reset counter ax
	mov 	si, 0
	sub 	di, 1
	jmp 	L3

EL3:
	mov 	byte[flagopen], 1
	jmp 	ETERNO
	
;*******************************************************************

DO_HISTOGRAM:
	mov 	ax, [flagopen]	
	cmp 	ax, 1
	je 	ALOWED0
	jmp 	ETERNO

ALOWED0:
	mov 	ax, [flaghist]	
	cmp 	ax, 0
	je 	ALOWED1
	jmp 	ETERNO

ALOWED1:
	mov 	si, image
	mov 	di, histogram
	mov 	cx, 62501
L2:
	mov 	bh, 00h
	mov 	bl, byte[si]
	add 	bx, bx
	add 	word[di+bx], 0001h
	inc 	si
	loop 	L2

	; plot histogram
	mov 	cx, 319
	mov 	bx, histogram
L6:
	cmp 	cx, 575
	je 	EL6
	mov 	dx, word[bx]
	shr 	dx, 4
	add 	dx, 250
	drawline cx, 250, cx, dx, branco_intenso
	add 	bx, 2 
	inc 	cx
	jmp 	L6
EL6:
	mov 	byte[flaghist], 1	
	jmp 	ETERNO	


;*******************************************************************

ACUMULATE:
	mov 	ax, [flaghist]	
	cmp 	ax, 1
	je 	ALOWED2
	jmp 	ETERNO

ALOWED2:
;	mov ax, [flageqhist]	
;	cmp ax, 0
;	je ALOWED3
;	jmp ETERNO

;ALOWED3:
	mov 	si, histogram
	mov 	di, cfd
	
	mov 	bx, [si]
	mov 	[di], bx
	add 	si, 2
	mov 	cx, 255
L4:
	mov 	bx, [si]
	add 	[di+2], bx
	mov 	bx, [di]
	add 	[di+2], bx
	add 	di, 2
	add 	si, 2
	loop 	L4

equalize:
	mov 	di, image
	mov 	cx, 62500
	mov 	bx, 62500

L7:
	mov 	al, byte[di]
	and 	ax, 00FFh
	mov 	si, ax
	add 	si, si
	mov 	ax, [cfd+si]
	mov	bx, 256	
	mul	bx	
	mov 	bx, 62500
	div 	bx
	mov 	[di], al
	inc 	di
	loop 	L7

DO_HISTOGRAM_EQ:
	mov 	si, image
	mov 	di, eqhistogram
	mov 	cx, 62501
L10:
	mov 	bh, 00h
	mov 	bl, byte[si]
	add 	bx, bx
	add 	word[di+bx], 0001h
	inc 	si
	loop 	L10

	; plot histogram
	mov 	cx, 319
	mov 	bx, eqhistogram

L5:
	cmp 	cx, 575
	je 	EL5
	mov 	dx, word[bx]
	shr 	dx, 4
	add 	dx, 16
	drawline cx, 16, cx, dx, branco_intenso
	add 	bx, 2 
	inc 	cx
	jmp 	L5

EL5:	
	mov byte[flageqhist], 1
	jmp PRINT	

LEFT_BUTTON_PRESSED:
	pusha
	writeword abrir, 1, 1, branco_intenso
	writeword sair, 1, 10,branco_intenso
	writeword hist, 1, 18,branco_intenso
	writeword eqhist, 1, 25,branco_intenso
	popa
	
	cmp 	dx, 48
	jg 	CASEO
	cmp 	cx, 63
	jl 	CASE1
	cmp 	cx, 127
	jl 	CASE2
	cmp 	cx, 191
	jl 	CASE3
	cmp 	cx, 255
	jl 	CASE4
	jmp 	ETERNO

CASEO:	
	jmp 	ETERNO
CASE1:
	writeword abrir, 1, 1, amarelo
	jmp 	OPEN
CASE2:
	writeword sair, 1, 10, amarelo
	jmp 	EXIT
CASE3:
	writeword hist, 1, 18, amarelo
	jmp 	DO_HISTOGRAM
CASE4:
	writeword eqhist, 1, 25, amarelo
	jmp 	ACUMULATE

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
; I R G B COR
; 0 0 0 0 preto
; 0 0 0 1 azul
; 0 0 1 0 verde
; 0 0 1 1 cyan
; 0 1 0 0 vermelho
; 0 1 0 1 magenta
; 0 1 1 0 marrom
; 0 1 1 1 branco
; 1 0 0 0 cinza
; 1 0 0 1 azul claro
; 1 0 1 0 verde claro
; 1 0 1 1 cyan claro
; 1 1 0 0 rosa
; 1 1 0 1 magenta claro
; 1 1 1 0 amarelo
; 1 1 1 1 branco intenso

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
hist    	db  		'HIST$'
eqhist    	db  		'HISTEQ$'
txhist    	db  		'HISTOGRAMA ORIGINAL$'
txeqhist    	db  		'HISTOGRAMA EQUALIZADO$'
nome    	db  		'RODOLFO VALENTIM$'
disc    	db  		'SISTEMAS EMBARCADOS 2016/1$'
filename	db		'imagem.txt', 0
buffer		db		0
handle 		dw 		0
input		db		0
flagopen	db		0
flaghist	db		0
flageqhist	db		0
histogram:	times		256 dw 0
cfd:		times		256 dw 0
eqhistogram: 	times		256 dw 0
image:		resb  		62500

;*************************************************************************

segment stack stack
   		resb 		256
stacktop:


