; global _start
global  atoi

section .data
        ten: dd 10
        test: db 0,10,0

section .text

;_start: enter 0, 0
;        mov ecx,dword [ebp+4]  ;Get argc
;        cmp ecx,2
;        jb end1
;        mov eax, dword [ebp+12] ; Get argument (pointer to string)
;        push eax
;        call atoi

print:
        mov byte[test],al
        mov eax,4
        mov ebx,1
        mov ecx,test
        mov edx,3
        int 80h
;end1:
;      mov eax,1
;      xor ebx,ebx
;      int 80h

atoi:
        push    ebp
        mov     ebp, esp        ; Entry code - set up ebp and esp
        push ecx
        push edx
        push ebx
        mov ecx, dword [ebp+8]  ; Get argument (pointer to string)
        xor eax,eax
        xor ebx,ebx
atoi_loop:
        xor edx,edx
        cmp byte[ecx],0
        jz  atoi_end
        imul dword[ten]
        mov bl,byte[ecx]
        sub bl,'0'
        add eax,ebx
        inc ecx
        jmp atoi_loop
atoi_end:
        pop ebx                 ; Restore registers
        pop edx
        pop ecx
        mov     esp, ebp        ; Function exit code
        pop     ebp
        ret

