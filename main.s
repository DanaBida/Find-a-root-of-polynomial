
section .data


printf_root:
	db "root = %.16e %.16e", 10, 0
scanf_epsilon:
      db 'epsilon = %lf',10,0 
scanf_order:
        db 'order = %d',10,0  
scanf_coeff:
     db 'coeff %d = %lf %lf',10,0 
scanf_inital:    
	db 'initial = %lf %lf',10,0 
print_error:               
	db 'ERROR - order equal to zero.',10,0


section .text
global main
extern printf
extern scanf
extern calloc
extern malloc

main:
	

	push    rbp
	mov     rbp, rsp
	sub     rsp, 60h
	
	;scanf("epsilon = %lf\n",&tolerance)
	lea     rax, [rbp-24] ;tolerance
	mov     rsi, rax
	mov     edi, scanf_epsilon ; "epsilon = %lf\n"
	mov     eax, 0
	call    scanf
	
	;scanf("order = %d\n",  &order)
	lea     rax, [rbp-68] ;order
	mov     rsi, rax
	mov     edi, scanf_order ; "order = %d\n"
	mov     eax, 0
	call    scanf
	
	mov     eax, [rbp-68]	;order
	test    eax, eax 		;check if order if zero 
	jnz     .orderNotZero
	mov     edi, print_error   ; "ERROR - order equal to zero."
	mov     eax, 0
	call    printf
	mov     eax, 0
	jmp     .finish
	
	.orderNotZero:
	;poly = malloc((order+1)*COEFFICIENT_SIZE)
	mov     eax, dword[rbp-68] ;order
	add     eax, 1
	cdqe
	shl     rax, 4
	mov     rdi, rax        ; size
	call    malloc
	
	;init for loop 
	mov     qword[rbp-16], rax ;poly
	mov     dword[rbp-60], 0 ;i 
	jmp     .checkLoop
	
	.loop:
	lea     rcx, [rbp-48] ;aImg
	lea     rdx, [rbp-56] ;aReal
	lea     rax, [rbp-64]	;polyIndex
	mov     rsi, rax
	mov     edi, scanf_coeff ; "coeff %d = %lf %lf\n"
	mov     eax, 0
	call    scanf
	
	mov     eax, dword[rbp-64]	;polyIndex
	cdqe
	shl     rax, 4
	mov     rdx, rax
	mov     rax, qword[rbp-16]	;poly
	add     rdx, rax
	mov     rax, qword[rbp-56]	;aReal
	mov     [rdx], rax
	mov     eax, dword[rbp-64]	;polyIndex
	cdqe   	;convert byte to word in order to use it in rax
	shl     rax, 4
	lea     rdx, [rax+8]
	mov     rax, qword[rbp-16]	;poly
	add     rdx, rax
	mov     rax, qword[rbp-48]	;aImg
	mov     [rdx], rax
	add     dword[rbp-60], 1	;I
	
		
	
	.checkLoop:
	mov     eax, dword[rbp-68]	;order
	cmp     dword[rbp-60], eax	;i
	jle     .loop
		
	
	
	lea     rdx, [rbp-32]	;startValImg
	lea     rax, [rbp-40]	;startValReal
	mov     rsi, rax
	mov     edi, scanf_inital ; "initial = %lf %lf\n"
	mov     eax, 0
	call    scanf
	
	
	mov     eax, [rbp-68]	;order
	cdqe
	shl     rax, 4
	mov     rdi, rax        ; size
	call    malloc
	
	
	mov     qword[rbp-8], rax	;dpoly
	mov     eax, dword[rbp-68]	;order
	mov     rdx, qword[rbp-8] 	;dpoly
	mov     rcx, qword[rbp-16]	;poly
	mov     rsi, rcx        ; poly
	mov     edi, eax        ; order
	call    derivePoly
	
	
	
	mov     r8d, dword[rbp-68] ; order
	mov     rdi, qword[rbp-32]	;startValImg
	mov     rsi, qword[rbp-40]	;startValReal
	mov     rax, qword[rbp-24]	;tolerance
	lea     rcx, [rbp-48] ; aImg
	lea     rdx, [rbp-56] ; aReal
	mov     r10, qword[rbp-8]	;dpoly
	mov     r9, qword[rbp-16]	;poly
	mov     qword[rbp-88], rdi
	movsd   xmm2, qword[rbp-88] ; startValI
	mov     qword[rbp-88], rsi
	movsd   xmm1, qword[rbp-88] ; startValR
	mov     rsi, r10        ; dpoly
	mov     rdi, r9         ; poly
	mov     qword[rbp-88], rax
	movsd   xmm0, qword[rbp-88] ; tolerance
	call    newtonAlgorithm
	
	
	mov     rdx, qword[rbp-48]	;aImg
	mov     rax, qword[rbp-56]	;aReal
	mov     qword[rbp-88], rdx
	movsd   xmm1, qword[rbp-88]
	mov     qword[rbp-88], rax
	movsd   xmm0, qword[rbp-88]
	mov     edi, printf_root ; "root = %.16e %.16e\n"
	mov     eax, 2
	call    printf
	mov     eax, 0
	
	.finish:
	leave
	retn


	
	
	
	
cmplx_add:
	nop
	enter 0, 0		; prepare a frame
	sub rsp, 0x20
	finit	                ; initialize the x87 subsystem
        movq [rbp-8] ,xmm0      ;push aReal
	fld qword[rbp-8]
	movq [rbp-16] ,xmm2    ;push bReal
	fld qword[rbp-16]
	faddp                   ;aReal+bReal
	fstp qword[rdi]
	
	
	movq [rbp-24] ,xmm1    ;push aImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	faddp                  ;aImg + bImg
	fstp qword[rsi]
	add rsp, 0x20
	leave 
	ret

cmplx_sub:
	nop
	enter 0, 0		; prepare a frame
	sub rsp, 0x20
	finit	                ; initialize the x87 subsystem
	movq [rbp-8] ,xmm0      ;push aReal
	fld qword[rbp-8]
	movq [rbp-16] ,xmm2    ;push bReal
	fld qword[rbp-16]
	fsubp st1,st0            ;aReal-bReal
	fstp qword[rdi]
	
	
	movq [rbp-24] ,xmm1    ;push aImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	fsubp st1,st0           ;aImg - bImg
	fstp qword[rsi]
	add rsp, 0x20
	leave 
	ret
	
cmplx_mul:
	nop
	enter 0, 0		; prepare a frame
	sub rsp, 0x20
	finit	; initialize the x87 subsystem

	
    movq [rbp-8] ,xmm0      ;push aReal
	fld qword[rbp-8]        
	movq [rbp-16] ,xmm2    ;push bReal
	fld qword[rbp-16]       
	fmulp                    ;aReal*bReal  
            
       
	movq [rbp-24] ,xmm1    ;push aImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	fmulp                  ;aImg*bImg ,aReal*bReal  

	fsubp st1, st0      ;st1-st0
	fstp qword[rdi]     ;insert aReal*bReal - aImg*bImg  into resReal 
	
        
    movq [rbp-24] ,xmm1     ;push aImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm2    ;push bReal
	fld qword[rbp-32]
	fmulp                  ;aImg*bReal
	
	
	movq [rbp-8] ,xmm0     ;push aReal
	fld qword[rbp-8]        
	movq [rbp-16] ,xmm3    ;push bImg
	fld qword[rbp-16]       
	fmulp                  ;aReal*bImg
	
    faddp st1
    fstp qword[rsi]        ;insert aImg*bReal + aReal*bImg into resImg
        
        
        
	add rsp, 0x20
	leave 
	ret

cmplx_div:
	nop
	enter 0, 0		; prepare a frame
	sub rsp, 0x20
	finit	; initialize the x87 subsystem

	
    movq [rbp-8] ,xmm0      ;push aReal
	fld qword[rbp-8]        
	movq [rbp-16] ,xmm2    ;push bReal
	fld qword[rbp-16]       
	fmulp                    ;aReal*bReal  
            
       
    movq [rbp-24] ,xmm1    ;push aImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	fmulp                  ;aImg*bImg ,aReal*bReal  
	
    
	faddp                 ;aReal*bReal +aImg*bImg
        
	movq [rbp-24] ,xmm2     ;push bReal
	fld qword[rbp-24]
	movq [rbp-32] ,xmm2    ;push bReal
	fld qword[rbp-32]
	fmulp                  ;bReal*bReal
	
	movq [rbp-24] ,xmm3     ;push bImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	fmulp                  ;bImg*bImg
	
	faddp                  ;bReal*bReal + bImg*bImg   st: bReal*bReal + bImg*bImg ,aReal*bReal +aImg*bImg (st1/st0)
	
	fdivp st1, st0
	fstp qword[rdi]     ;insert aReal*bReal - aImg*bImg  into resReal 
	
	
	movq [rbp-8] ,xmm1      ;push aImg
	fld qword[rbp-8]        
	movq [rbp-16] ,xmm2    ;push bReal
	fld qword[rbp-16]       
	fmulp                    ;aImg*bReal  
            
       
	movq [rbp-24] ,xmm0    ;push aReal
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	fmulp                  ;aReal*bImg ,aImg*bReal  
	
    
	fsubp st1,st0            ;aImg*bReal - aReal*bImg
        
	movq [rbp-24] ,xmm2     ;push bReal
	fld qword[rbp-24]
	movq [rbp-32] ,xmm2    ;push bReal
	fld qword[rbp-32]
	fmulp                  ;bReal*bReal
	
	movq [rbp-24] ,xmm3     ;push bImg
	fld qword[rbp-24]
	movq [rbp-32] ,xmm3    ;push bImg
	fld qword[rbp-32]
	fmulp                  ;bImg*bImg
	
	faddp                  ;bReal*bReal + bImg*bImg   st: bReal*bReal + bImg*bImg ,aReal*bReal +aImg*bImg (st1/st0)
	
	fdivp st1, st0
	fstp qword[rsi]     ;insert aReal*bReal - aImg*bImg  into resReal 

    add rsp, 0x20 
	leave 
	ret
mulAndAdd:
	nop
	push rbp
	mov rbp,rsp
	sub rsp, 0x50
	finit	; initialize the x87 subsystem
	
	movq [rbp-8] ,xmm0    	;insert aReal
	movq [rbp-16] ,xmm1   	;insert aImg
	movq [rbp-24] ,xmm2    	;insert bReal
	movq [rbp-32] ,xmm3    	;insert bImg
	movq [rbp-40] ,xmm4    	;insert cReal
	movq [rbp-48] ,xmm5    	;insert cImg
	mov [rbp-56]  ,rdi      ;insert &resReal
	mov [rbp-64]  ,rsi      ;insert &resImg
	lea rsi, [rbp-72]       ;save place for tempImg
	lea rdi, [rbp-80]       ;save place for tempReal

	movsd   xmm3, [rbp-32] ; bImg
	movsd   xmm2, [rbp-24] ; bReal
	movsd   xmm1, [rbp-16] ; aImg
	
	movsd   xmm0, [rbp-8] ; aReal
	call    cmplx_mul
	
	mov     rsi, [rbp-64] ; resImg
	mov     rdi, [rbp-56] ; resReal
	movsd   xmm3, [rbp-48] ; cImg
	movsd   xmm2, [rbp-40] ; cReal	
	movsd   xmm1, [rbp-72] ; resImg
	movsd   xmm0, [rbp-80] ; resReal
	call    cmplx_add
	add rsp, 0x50
	pop     rbp
	retn

getReal:
	nop
	push rbp
	mov rbp,rsp
	sub rsp, 0x18
	
	mov [rbp-8] ,rdi ;index
	mov [rbp-16],rsi  ;&resReal
	mov	[rbp-24],rdx  ;&poly
	
	mov rax, [rbp-8]  ;rax<-index
	shl rax,4			;rax<-index*2
	add rax, qword[rbp-24] ;rax<-index*2  +poly
	mov     rax, [rax]
	mov     rdx, [rbp-16]
	mov     [rdx], rax
	add rsp, 0x18
	pop     rbp
	retn
	

getImg:
	nop
	push rbp
	mov rbp,rsp
	sub rsp, 0x18
	
	mov [rbp-8] ,rdi ;index
	mov [rbp-16],rsi  ;&resReal
	mov	[rbp-24],rdx  ;&poly
	
	mov rax, [rbp-8]  ;rax<-index
	shl rax,4			;rax<-index*2
	add rax,8
	add rax, qword[rbp-24] ;rax<-index*2 +1 +poly
	
	mov     rax, [rax]
	mov     rdx, [rbp-16]
	mov     [rdx], rax
	add rsp, 0x18
	pop     rbp
	retn
	
derivePoly:
	nop
	push rbp
	mov rbp,rsp	
	sub rsp, 0x40
	
	mov     [rbp-8], rdi 	;order
	mov     [rbp-16], rsi	;poly
	mov     [rbp-24], rdx	;dpoly
	mov     qword[rbp-32],1  	;i<-1
	
	.loop:
		mov     rax, [rbp-32] 	;i
		cmp     rax, [rbp-8]	;order
		jle     .for_loop		;check if i<=order
		add rsp, 0x40
		pop     rbp
		retn
	
	.for_loop:
		mov     rax, [rbp-32]	;i
		sub     rax, 1
		shl     rax, 4		;mul by 16
		mov     rdx, rax	;rdx<-(i-1)*16
		mov     rax, [rbp-24]	;dpoly
		add     rax, rdx
		mov     [rbp-40], rax	;resReal<-dpoly +(i-1)*16
		
		mov     rax, [rbp-32]	
		sub		rax, 1		;(i-1)
		shl     rax, 4		;mul by 16
		lea     rdx, [rax+8]	
		
		mov     rax, [rbp-24]
		add     rax, rdx		;rax<-dpoly +(i-1)*16 +8
		mov 	[rbp-48], rax		;resImg<-dpoly +(i-1)*16 +8


		;getReal(int index,double* resReal, double* poly)
		;resReal is a paramter that will contain the value in i
		;double real is a local variable
		mov     rdx, [rbp-16] ; poly
		lea     rsi, [rbp-56]	;&real
		mov     rdi, [rbp-32]	;i
		call    getReal
		

		mov     rdx, [rbp-16] ; poly
		lea     rsi, [rbp-64]	;&img
		mov     rdi, [rbp-32]	;i
		call    getImg
		
		;cmplx_mul(double aReal, double aImg , double bReal, double bImg , double *resReal, double *resImg )
		
		movsd   xmm0, [rbp-56] ; real
		movsd   xmm1, [rbp-64] ; img
		
		cvtsi2sd xmm2, [rbp-32] ;i
		xorpd xmm3, xmm3		;0
		mov rdi,	[rbp-40]
		mov rsi,	[rbp-48]
		call cmplx_mul
		add     qword[rbp-32], 1
		jmp .loop

;int continueAlgo(double resReal, double resImg, double tolerance);
continueAlgo:
	push    rbp
	mov     rbp, rsp
	sub     rsp, 0x28
	finit	; initialize the x87 subsystem
	
	;movsd   [rbp-8], xmm0	;resReal
	;movsd   [rbp-16], xmm1	;resImg
	;movsd   [rbp-24], xmm2	;tolerance
	
	movsd   [rbp-8], xmm0
	movsd   [rbp-16], xmm1
	movsd   [rbp-24], xmm2
	movsd   xmm0, [rbp-8]
	movapd  xmm1, xmm0
	mulsd   xmm1, [rbp-8]
	movsd   xmm0, [rbp-16]
	mulsd   xmm0, [rbp-16]
	addsd   xmm0, xmm1
	movsd   [rbp-32], xmm0	;res
	movsd   xmm0, [rbp-24]
	mulsd   xmm0, [rbp-24] ;tol
	movsd   [rbp-40], xmm0 ;tol*tol
	movsd   xmm0, [rbp-32] ;res
	ucomisd xmm0, [rbp-40]
	jbe     .false
	mov     eax, 1
	jmp     .finish
	.false:
		mov     eax, 0
	.finish:
		add     rsp, 0x28
		pop     rbp
		retn


;void newtonAlgorithm(double tolerance, double* poly,double* dpoly, double startValR, double startValI,double* resReal,double* resImg,int order);
newtonAlgorithm:
	push    rbp
	mov     rbp, rsp
	sub     rsp, 0x80 
	
	movsd   [rbp-8], xmm0		;tolerance
	mov     [rbp-16], rdi		;poly
	mov     [rbp-24], rsi		;dpoly
	movsd   [rbp-32], xmm1		;startValR
	movsd   [rbp-40], xmm2		;startValI
	mov     [rbp-48], rdx		;resReal
	mov     [rbp-56], rcx		;resImg
	mov     [rbp-64], r8			;order
	
	.loop:
		;evalPoly(poly,startValR,startValI,&zPolvalReal,&zPolvalImg,order);
		mov     rcx, [rbp-64]			;order
		lea     rdx, [rbp-72] 			;&zPolvalImg
		lea     rsi, [rbp-80]			;&zPolvalReal
		mov     rdi, [rbp-40]			;startValI
		mov     [rbp-128], rdi
		movsd   xmm1, [rbp-128] 		;resImg
		mov     rax, [rbp-32]			;startValR
		mov     [rbp-128], rax
		movsd   xmm0,	[rbp-128] 
		mov     rdi, [rbp-16]				;poly
		call    evalPoly
		
		;evalPoly(dpoly,startValR,startValI,&zdivValReal,&zdivValImg,order-1);
		mov     rax, [rbp-64]
		lea     rcx, [rax-1]    	;order-1
		lea     rdx, [rbp-88] 		;zdivValImg 
		lea     rsi, [rbp-96] 		;zdivValReal
		mov     rdi, [rbp-40]		;startValI
		mov     [rbp-128], rdi
		movsd   xmm1, [rbp-128]
		mov     rax, [rbp-32]		;startValR
		mov     [rbp-128], rax
		movsd   xmm0, [rbp-128] 
		mov     rdi, [rbp-24]		;dpoly 
		call    evalPoly
		
		;cmplx_div(zPolvalReal,zPolvalImg,zdivValReal,zdivValImg,resReal,resImg)
		mov     rsi, [rbp-56] 			;resImg
		mov     rdi, [rbp-48] 			;resReal
		movsd   xmm3, [rbp-88] 			;zdivValImg
		movsd   xmm2, [rbp-96] 			;zdivValReal
		movsd   xmm1, [rbp-72] 			;zPolvalImg
		movsd   xmm0, [rbp-80] 			;zPolvalReal
		call    cmplx_div
		
		;cmplx_sub(startValR,startValI,*resReal,*resImg,resReal,resImg)
		mov     rax, [rbp-56]			;resImg
		mov     r8, [rax]
		mov     rax, [rbp-48]			;resReal
		mov     rcx, [rax]
		mov     rsi, [rbp-56] 			;resImg
		mov     rdi, [rbp-48] 			;resReal
		movsd   xmm1, [rbp-40] 			;startValI			
		movsd   xmm0, [rbp-32] 			;startValR
		mov     [rbp-104], r8			
		movsd   xmm3, [rbp-104] 		;resImg
		mov     [rbp-104], rcx			;resReal
		movsd   xmm2, [rbp-104] 		;resReal
		call    cmplx_sub
		
		;startValR = *resReal;
		mov     rax, [rbp-48]			;resReal
		mov     rax, [rax]				;rax<-resReal
		mov     [rbp-32], rax			;startValR
		;startValI = *resImg;
		mov     rax, [rbp-56]			;resImg
		mov     rax, [rax]				;rax<-resImg
		mov     [rbp-40], rax			;startValI
		
		;evalPoly(poly,*resReal,*resImg,&cReal,&cImg,order)
		mov     rax, [rbp-56]			;resImg
		mov     rdi, [rax]
		mov     rax, [rbp-48]			;resReal
		mov     rax, [rax]
		mov     ecx, [rbp-64] 			;order
		lea     rdx, [rbp-112] 			;cImg
		lea     rsi, [rbp-120] 			;cReal
		mov     r8, [rbp-16]			;poly
		mov     [rbp-128], rdi
		movsd   xmm1, [rbp-128] 		;resImg
		mov     [rbp-128], rax
		movsd   xmm0, [rbp-128] 		;resReal
		mov     rdi, r8         		; poly
		call    evalPoly
		
		mov     rdx, [rbp-112]				;cImg
		mov     rax, [rbp-120]				;cReal
		mov     rcx, [rbp-8]				;tolerance
		mov     [rbp-128], rcx
		movsd   xmm2, [rbp-128] ; tolerance
		mov     [rbp-128], rdx
		movsd   xmm1, [rbp-128] ; resImg
		mov     [rbp-128], rax
		movsd   xmm0, [rbp-128] ; resReal
		call    continueAlgo
		test    al, al
		jnz     .loop
		add rsp, 0x80
		pop     rbp
		retn
	

;evalPoly(double *poly, double zReal, double zImg, double *resReal, double *resImg, int order)
evalPoly:
	nop
	push rbp
	mov rbp,rsp	
	sub rsp, 0x50
	mov     [rbp-8], rdi	;poly 
	movsd   [rbp-16], xmm0	;zReal
	movsd   [rbp-24], xmm1	;zImg
	mov     [rbp-32], rsi	;&resReal
	mov     [rbp-40], rdx	;&resImg
	mov     [rbp-48], rcx	;order
	mov     rdx, [rbp-32]	;rdx<-the address of resReal
	mov     rax, 0
	mov     [rdx], rax	;	resReal<-0
	mov     rdx, [rbp-40]	;rdx<-the address of resImg
	mov     rax, 0
	mov     [rdx], rax		;resImg<-0
	mov     rax, [rbp-48]	;rax<-order
	mov     [rbp-56], rax	;i<-order
	.loop:
		cmp qword[rbp-56], 0  ;compare i to 0
		jns .for_loop	;if i>=0(jump not signed)
		add rsp, 0x50
		pop     rbp
		retn
	.for_loop:             
		;getReal(i,&polyRealItem,poly)
		mov     rdx, [rbp-8]; poly
		lea     rsi, [rbp-64];&polyRealItem
		mov     rdi, [rbp-56];i
		call    getReal
		;getImg(i,&polyImgItem,poly)
		mov     rdx, [rbp-8] ; poly
		lea     rsi, [rbp-72];&polyImgItem
		mov     rdi, [rbp-56];i
		call    getImg
		
		;mulAndAdd(*resReal,*resImg,zReal,zImg,polyRealItem,polyImgItem,resReal ,resImg)
		mov     rax, [rbp-40]	;&resImg
		mov     rdx, [rax]		;rdx<-the value in resImg
		mov     [rbp-80], rdx
		movsd   xmm1, [rbp-80] ; xmm1<-resImg
		mov     rax, [rbp-32]	;&resReal
		mov     rax, [rax]		;rax<-the value in resReal
		mov     [rbp-80], rax
		movsd   xmm0, [rbp-80] ; xmm0<-resReal
		mov     rsi, [rbp-40] 	;rsi<-&resImg
		mov     rdi, [rbp-32] 	;rdi<-&resReal
		movsd   xmm5, [rbp-72] 		;xmm5<-polyImgItem
		movsd   xmm4, [rbp-64] ; xmm4<-polyRealItem
		movsd   xmm3, [rbp-24] ; xmm<-zImg
		movsd   xmm2, [rbp-16] ; xmm2<-zReal
		call    mulAndAdd
		sub     qword[rbp-56], 1
		jmp .loop




