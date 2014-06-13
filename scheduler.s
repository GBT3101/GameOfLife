        global scheduler
        extern resume, end_co
        extern WorldWidth,WorldLength,beats,generations_num
        extern make_a_beat

section .data
cors_num: 	db 0 ; the number of coroutines+2
section .text

scheduler:
	call 	calculate_cors_num
	mov 	ebx, 1
	call 	resume	
	mov 	ebx, 0 ; number of generations
.loop_generations:
	cmp 	bl, byte[generations_num]
	je 		.end_loop
	call 	loop_for_coroutines
	call 	loop_for_coroutines
	xor 	edx, edx
	xor 	ecx,ecx
	xor 	eax,eax
	mov 	cl, byte[beats]
	mov 	al, bl
	div 	cl 			;edx::eax/cl
	cmp 	edx, 0
	jne 	.do_not_print
	push 	ebx
	mov 	ebx, 1
	call 	resume	
	pop 	ebx
.do_not_print:
	inc 	ebx
	jmp 	.loop_generations
.end_loop:	
	mov 	ebx, 1
	call 	resume
    call 	end_co             ; stop co-routines

calculate_cors_num:
	push    ebp
    mov     ebp, esp
    pusha
    xor 	eax,eax
    xor 	ebx,ebx
    mov 	al, byte[WorldWidth]
    mov 	bl, byte[WorldLength]
    imul 	eax, ebx
    add 	al, 2
    mov 	byte[cors_num], al
    popa
    mov 	esp, ebp
    pop 	ebp
    ret

loop_for_coroutines:
	push 	ebx
	mov ebx, 2
.loop_coroutines:
	; here we will go over all the coroutines and make a beat
	cmp 	bl, byte[cors_num]
	je 		.end_coroutines_loop
	call 	resume
	inc 	ebx
	jmp 	.loop_coroutines
.end_coroutines_loop:
	pop 	ebx
	ret



