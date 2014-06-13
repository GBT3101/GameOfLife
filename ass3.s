        global _start
        global get_values_array
        global set_a_value
        global get_width
        global get_length
        global get_generations_num
        global get_beats
        global WorldWidth
        global WorldLength
        global generations_num
        global beats
        extern init_co, start_co, resume, make_a_beat
        extern scheduler, printer
        extern atoi


        ;; /usr/include/asm/unistd_32.h

%macro  syscall1 2
        mov     ebx, %2
        mov     eax, %1
        int     0x80
%endmacro

%macro  syscall3 4
        mov     edx, %4
        mov     ecx, %3
        mov     ebx, %2
        mov     eax, %1
        int     0x80
%endmacro

%macro  exit 1
        syscall1 1, %1
%endmacro

%macro  write 3
        syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
        syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
        syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
        syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
        syscall1 6, %1
%endmacro


maxcors:        equ 100*100         ; maximum number of co-routines
sys_exit:       equ   1


section .data


file_descriptor: db   0    
buffer:          db   0
WorldWidth:      db   0
WorldLength:     db   0
generations_num: db   0
beats:           db   0
values_array:    times maxcors  db 0
pointer_in_values: dd   0
error_message: db "There is a problem with the init file", 10, 0


section .text

_start:
        enter   0, 0

        push    ebp
        call    init_arguments

        xor     ebx, ebx            ; scheduler is co-routine 0
        mov     edx, scheduler
        mov     ecx, [ebp + 4]      ; ecx = argc
        call    init_co            ; initialize scheduler state

        inc     ebx                 ; printer i co-routine 1
        mov     edx, printer
        call    init_co            ; initialize printer state

        push    ebp
        call    init_array
        add     esp, 4




        xor     ebx, ebx            ; starting co-routine = scheduler
        call    start_co           ; start co-routines

exit_program:
        mov     eax, sys_exit
        xor     ebx, ebx
        int     80h

init_arguments:
        push    ebp
        mov     ebp, esp
        pusha

        mov     edi, dword[ebp+8]
        mov     eax, dword[edi+16] ; read the length
        push    eax
        call    atoi
        add     esp, 4
        mov     byte[WorldLength], al
        mov     eax, dword[edi+20] ; read the width
        push    eax
        call    atoi
        add     esp, 4
        mov     byte[WorldWidth], al
        mov     eax, dword[edi+24] ; read the number of generations
        push    eax
        call    atoi
        add     esp, 4
        mov     byte[generations_num], al
        mov     eax, dword[edi+28] ; read the number of beats every print
        push    eax
        call    atoi
        add     esp, 4
        mov     byte[beats], al

        popa
        mov     esp, ebp
        pop     ebp
        ret


init_array:
        push    ebp
        mov     ebp, esp
        pusha
        xor     ecx, ecx
        mov     edi, dword[ebp+8]
        pusha
        open    dword[edi+12], 0, 0 ; open the file
        mov     byte [file_descriptor], al ;saving the file descriptor
        popa
        mov     eax, values_array
        mov     dword[pointer_in_values], eax
.loop_read:
        mov     ebx, dword[pointer_in_values]
        sub     ebx, values_array
        xor     edx,edx
        mov     eax,ebx
        mov     cl, byte[WorldWidth]
.break1:
        div     ecx ;now eax has the i, and edx has the j
.break2:
        mov     ecx, edx ; now ecx is j
        add     ebx, 2
        mov     edx, make_a_beat
        call    init_co

        xor     eax, eax
        mov     al, byte [file_descriptor]
        pusha
        read    eax, buffer, 1                ; read 1 byte from the file.
        cmp     eax, 0 ; couldnt read anything
        popa
        je      .end_loop
        cmp     byte [buffer], '1' ; check if its a live cell.
        je      .live_cell
        cmp     byte [buffer], ' ' ; check if its a dead cell.
        je      .dead_cell
        cmp     byte [buffer], 10 ; ignore a new line
        jne     .very_bad_syntax ; something that is not ' ', '1', 10 or 0.
        jmp     .loop_read
.live_cell:
        mov     edx, dword[pointer_in_values]
        mov     byte[edx], '1'
        inc     dword[pointer_in_values]
        jmp     .loop_read
        
.dead_cell:
        mov     edx, dword[pointer_in_values]
        mov     byte[edx], ' '
        inc     dword[pointer_in_values]
        jmp     .loop_read

.very_bad_syntax:
        write   1, error_message, 38
        jmp     exit_program
.end_loop:
        popa
        mov     esp, ebp
        pop     ebp
        ret


get_values_array: ; get i and j coordinates, and returns the VALUE of this corutine.
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        pusha
        xor     ecx,ecx
        mov     ebx, dword[ebp+12] ; i coordinate
        mov     edx, dword[ebp+8] ; j coordinate
        mov     cl, byte[WorldWidth]
        imul    ebx, ecx ; now ebx = i*width
        add     edx, values_array ; now ebx = startMatrix+i*width
        add     ebx, edx ; now ebx = startMatrix+i*width+j, so we are in the right courotine
        xor     eax, eax
        mov     al, byte[ebx]
       ; xor     ebx, ebx
       ; mov     bl, byte[eax] ; get the value itself
        mov     dword[ebp-4], eax
        popa
        mov     eax, dword[ebp-4]
        mov     esp, ebp
        pop     ebp
        ret

set_a_value: ;gets i j and a value, and sets this value to coordinate i,j
        push    ebp
        mov     ebp, esp
        pusha
        xor     ecx,ecx
        mov     ebx, dword[ebp+16] ; i coordinate
        mov     edx, dword[ebp+12] ; j coordinate
        mov     cl, byte[WorldWidth]
        imul    ebx, ecx ; now ebx = i*width
        add     edx, values_array ; now ebx = startMatrix+i*width
        add     ebx, edx ; now ebx = startMatrix+i*width+j, so we are in the right courotine
        xor     eax, eax
        mov     ecx, dword[ebp+8] ; the value
        mov     byte[ebx], cl
        popa
        mov     esp, ebp
        pop     ebp
        ret
