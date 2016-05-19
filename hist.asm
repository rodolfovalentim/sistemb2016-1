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

%macro ponto 2			; x,y,color
	add %1, 3
	add %2, 100
	push %1
	push %2	
	call plot_xy
	sub %1, 3
	sub %2, 100
%endmacro

%macro writeword 3
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
    	mov ax,data
    	mov ds,ax
    	mov ax,stack
    	mov ss,ax
    	mov sp,stacktop

;*******************************************************************

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

	;cmp dl, '0'
	;jl finishread

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

;*******************************************************************

doHistogram:
	mov si, image
	mov di, histogram
	mov cx, 62501
L2:
	mov bl, byte[si]
	add bx, bx
	add word[di+bx], 0001h
	inc si
	loop L2

;*******************************************************************

acumulate:
	mov si, histogram
	mov di, cfd
	
	mov bx, [si]
	mov [di], bx
	add si, 2
	mov cx, 255
L4:
	mov bx, [si]
	add [di+2], bx
	mov bx, [di]
	add [di+2], bx
	add di, 2
	add si, 2
	loop L4

equalize:
	;mov di, image
	;mov cx, 62500
	;mov bx, 62500
	
	;int 3
	;or ax, ax
	
L7:
	;mov al, byte[di]
	;and ax, 00FFh
	;mov si, ax
	;add si, si
	;mov ax, [cfd+si]
	;div bx
	;shr ax, 8
	;mov [di], al
	;inc di
	;loop L7

; salvar modo corrente de video(vendo como esta o modo de video da maquina)
        mov 	ah,0Fh
    	int 	10h
    	mov 	[modo_anterior],al   

; alterar modo de video para gráfico 640x480 16 cores
    	mov    	al,12h
   	mov    	ah,0
    	int    	10h
	
;escrever uma mensagem

	drawline 255, 0, 255, 479, branco_intenso
	drawline 255, 239, 639, 239, branco_intenso
	drawline 63, 479, 63, 431, branco_intenso
	drawline 127, 479, 127, 431, branco_intenso
	drawline 191, 479, 191, 431, branco_intenso
	drawline 0, 431, 255, 431, branco_intenso
	drawline 0, 63, 255, 63, branco_intenso

	writeword abrir, 1, 1
	writeword sair, 1, 10
	writeword hist, 1, 18
	writeword eqhist, 1, 25
	writeword txhist, 1, 33
	writeword txeqhist, 16, 33
	writeword nome, 27, 1
	writeword disc, 28, 1

	mov si, 0  	; x
	mov di, 249	; y
	mov bx, image
	
L3:	cmp di, 0
	je EL3
	mov ah, 00h
	mov al, byte[bx]
	shr al, 4
	mov byte[cor], al	
	ponto si, di
	inc si
	inc bx	
	cmp si, 250
	je RCAX
	jmp L3
RCAX:	;reset counter ax
	mov si, 0
	sub di, 1
	jmp L3
EL3: 	; end of loop 3		

	; plot histogram
	mov cx, 319
	mov bx, histogram
L5:
	cmp cx, 575
	je EL5
	mov dx, word[bx]
	shr dx, 9
	add dx, 16
	drawline cx, 16, cx, dx, branco_intenso
	add bx, 2 
	inc cx
	jmp L5
EL5: 	; end of loop 3	

	; plot histogram
	mov cx, 319
	mov bx, cfd
L6:
	cmp cx, 575
	je EL6
	mov dx, word[bx]
	shr dx, 9
	add dx, 250
	drawline cx, 250, cx, dx, branco_intenso
	add bx, 2 
	inc cx
	jmp L6
EL6: 	; end of loop 6

	; equalize image
	mov cx, 62500
	m
		
	
	mov ah,08h
	int 21h
	mov ah,0   			; set video mode
	mov al,[modo_anterior]   	; modo anterior
	int 10h

	mov ah, 4Ch
	int 21h
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
;_____________________________________________________________________________
;    fun��o circle
;	 push xc; push yc; push r; call circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor
circle:
	push 	bp
	mov	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	mov	ax,[bp+8]    ; resgata xc
	mov	bx,[bp+6]    ; resgata yc
	mov	cx,[bp+4]    ; resgata r
	mov 	dx,bx	
	add	dx,cx       ;ponto extremo superior
	push    ax			
	push	dx
	call	plot_xy
	mov	dx,bx
	sub	dx,cx       ;ponto extremo inferior
	push    ax			
	push	dx
	call 	plot_xy
	mov 	dx,ax	
	add	dx,cx       ;ponto extremo direita
	push    dx			
	push	bx
	call	plot_xy
	mov	dx,ax
	sub	dx,cx       ;ponto extremo esquerda
	push    dx			
	push	bx
	call	plot_xy
	mov	di,cx
	sub	di,1	 ;di=r-1
	mov	dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay:				;loop
	mov	si,di
	cmp	si,0
	jg	inf       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov	si,dx		;o jl � importante porque trata-se de conta com sinal
	sal	si,1		;multiplica por doi (shift arithmetic left)
	add	si,3
	add	di,si     ;nesse ponto d=d+2*dx+3
	inc	dx		;incrementa dx
	jmp	plotar
inf:	
	mov	si,dx
	sub	si,cx  		;faz x - y (dx-cx), e salva em di 
	sal	si,1
	add	si,5
	add	di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc	dx		;incrementa x (dx)
	dec	cx		;decrementa y (cx)
	
plotar:	
	mov	si,dx
	add	si,ax
	push    si			;coloca a abcisa x+xc na pilha
	mov	si,cx
	add	si,bx
	push    si			;coloca a ordenada y+yc na pilha
	call plot_xy		;toma conta do segundo octante
	mov	si,ax
	add	si,dx
	push    si			;coloca a abcisa xc+x na pilha
	mov	si,bx
	sub	si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do s�timo octante
	mov	si,ax
	add	si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov	si,bx
	add	si,dx
	push    si			;coloca a ordenada yc+x na pilha
	call plot_xy		;toma conta do segundo octante
	mov	si,ax
	add	si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov	si,bx
	sub	si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do oitavo octante
	mov	si,ax
	sub	si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov	si,bx
	add	si,cx
	push    si			;coloca a ordenada yc+y na pilha
	call plot_xy		;toma conta do terceiro octante
	mov	si,ax
	sub	si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov	si,bx
	sub	si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do sexto octante
	mov	si,ax
	sub	si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov	si,bx
	sub	si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quinto octante
	mov	si,ax
	sub	si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov	si,bx
	add	si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quarto octante
	
	cmp	cx,dx
	jb	fim_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp	stay		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_circle:
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop 	ax
	popf
	pop	bp
	ret	6
;-----------------------------------------------------------------------------
;    fun��o full_circle
;	 push xc; push yc; push r; call full_circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor					  
full_circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov		si,bx
	sub		si,cx
	push    ax			;coloca xc na pilha			
	push	si			;coloca yc-r na pilha
	mov		si,bx
	add		si,cx
	push	ax		;coloca xc na pilha
	push	si		;coloca yc+r na pilha
	call line
	
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay_full:				;loop
	mov		si,di
	cmp		si,0
	jg		inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar_full
inf_full:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar_full:	
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call 	line
	
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call	line
	
	cmp		cx,dx
	jb		fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay_full		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_full_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;
;   fun��o line
;
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
	push		bp
	mov		bp,sp
	pushf                        ;coloca os flags na pilha
	push 		ax
	push 		bx
	push		cx
	push		dx
	push		si
	push		di
	mov		ax,[bp+10]   ; resgata os valores das coordenadas
	mov		bx,[bp+8]    ; resgata os valores das coordenadas
	mov		cx,[bp+6]    ; resgata os valores das coordenadas
	mov		dx,[bp+4]    ; resgata os valores das coordenadas
	cmp		ax,cx
	je		line2
	jb		line1
	xchg		ax,cx
	xchg		bx,dx
	jmp		line1
line2:		; deltax=0
	cmp		bx,dx  ;subtrai dx de bx
	jb		line3
	xchg		bx,dx        ;troca os valores de bx e dx entre eles
line3:	; dx > bx
	push		ax
	push		bx
	call 		plot_xy
	cmp		bx,dx
	jne		line31
	jmp		fim_line
line31:	inc		bx
	jmp		line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
	; cx > ax
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		ja		line32
		neg		dx
line32:		
		mov		[deltay],dx
		pop		dx

		push		ax
		mov		ax,[deltax]
		cmp		ax,[deltay]
		pop		ax
		jb		line5

	; cx > ax e deltax>deltay
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx

		mov		si,ax
line4:
		push		ax
		push		dx
		push		si
		sub		si,ax	;(x-x1)
		mov		ax,[deltay]
		imul		si
		mov		si,[deltax]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar1
		add		ax,si
		adc		dx,0
		jmp		arc1
ar1:		sub		ax,si
		sbb		dx,0
arc1:
		idiv		word [deltax]
		add		ax,bx
		pop		si
		push		si
		push		ax
		call		plot_xy
		pop		dx
		pop		ax
		cmp		si,cx
		je		fim_line
		inc		si
		jmp		line4

line5:		cmp		bx,dx
		jb 		line7
		xchg		ax,cx
		xchg		bx,dx
line7:
	push cx
	sub cx,ax
	mov  [deltax],cx
	pop  cx
	push dx
	sub dx,bx
	mov [deltay],dx
	pop dx
	mov si,bx
line6:
	push dx
	push si
	push ax
	sub  si,bx	;(y-y1)
	mov  ax,[deltax]
	imul si
	mov  si,[deltay]		;arredondar
	shr  si,1
; se numerador (DX)>0 soma se <0 subtrai
	cmp  dx,0
	jl   ar2
	add  ax,si
	adc  dx,0
	jmp  arc2
ar2:	
	sub ax, si
	sbb dx, 0
arc2:
	idiv word [deltay]
	mov di, ax
	pop ax
	add di, ax
	pop si
	push di
	push si
	call plot_xy
	pop dx
	cmp si, dx
	je  fim_line
	inc si
	jmp line6

fim_line:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	pop bp
	ret 8
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
txeqhist    	db  		'HISTOGRAMA ORIGINAL$'
txhist    	db  		'HISTOGRAMA EQUALIZADO$'
nome    	db  		'RODOLFO VALENTIM$'
disc    	db  		'SISTEMAS EMBARCADOS 2016/1$'
filename	db		'teste.txt', 0
buffer		db		0
handle 		dw 		0
input		db		0
histogram:	times		256 dw 0
cfd:		times		256 dw 0
image:		resb  		62500

;*************************************************************************

segment stack stack
   		resb 		256
stacktop:


