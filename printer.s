        global printer
        extern resume
        extern get_values_array
        extern WorldWidth,WorldLength,beats,generations_num

        ;; /usr/include/asm/unistd_32.h

%macro  write 2
        mov     edx, %2 ;number of chars
        mov     ecx, %1 ;string
        mov     ebx, 1
        mov     eax, 4
        int     0x80
%endmacro

section .data
buffer:         db 0
newLine:        db 10
seperator:      db "****************"
        

section .text

printer:
.loop:
        mov     ebx, 0 ; ebx is i
        mov     ecx, 0; ecx is j     
.loop_i:
        cmp     bl, byte[WorldLength]
        je      .end_loop_i
.loop_j:
        cmp     cl, byte[WorldWidth]
        je      .end_loop_j
        push    ebx
        push    ecx
        call    get_values_array
        add     esp,8
        mov     byte[buffer], al
        pusha
        write   buffer, 1
        popa
        inc     ecx
        jmp     .loop_j

.end_loop_j:
        pusha
        write   newLine, 1
        popa
        mov ecx, 0
        inc     ebx
        jmp     .loop_i

.end_loop_i:
        pusha
        write   seperator, 16
        write   newLine, 1
        popa
        xor ebx, ebx
        call resume             ; resume scheduler
        
        jmp .loop