;;; This is a simplified co-routines implementation:
;;; CORS contains just stack tops, and we always work
;;; with co-routine indexes.
        global init_co, start_co, end_co, resume, make_a_beat
        extern get_width
        extern get_length
        extern get_values_array
        extern set_a_value
        extern WorldWidth,WorldLength,beats,generations_num


maxcors:        equ 100*100+2         ; maximum number of co-routines
stacksz:        equ 128     ; per-co-routine stack size


section .bss

stacks: resb maxcors * stacksz  ; co-routine stacks
cors:   resd maxcors            ; simply an array with co-routine stack tops
curr:   resd 1                  ; current co-routine
origsp: resd 1                  ; original stack top
tmp:    resd 1                  ; temporary value

section .data


startX:          dd   0
startY:          dd   0
endX:            dd   0
endY:            dd   0
temporary_array:    times maxcors  db 0 ; a temporary array holding the next generation values


section .text

        ;; ebx = co-routine index to initialize
        ;; edx = co-routine start
        ;; other registers will be visible to co-routine after "start_co"
init_co:

        push eax                ; save eax (on callers stack)
	push edx
	mov edx,0
	mov eax,stacksz
        imul ebx			    ; eax = co-routines stack offset in stacks
        pop edx
	add eax, stacks + stacksz ; eax = top of (empty) co-routines stack
        mov [cors + ebx*4], eax ; store co-routines stack top
        pop eax                 ; restore eax (from callers stack)

        mov [tmp], esp          ; save callers stack top
        mov esp, [cors + ebx*4] ; esp = co-routines stack top

        push    eax
        push    ecx
        push    edx                ; save return address to co-routine stack
        pushf                   ; save flags
        pusha                   ; save all registers
        mov [cors + ebx*4], esp ; update co-routines stack top

        mov esp, [tmp]          ; restore callers stack top
        ret                     ; return to caller

        ;; ebx = co-routine index to start
start_co:
        pusha                   ; save all registers (restored in "end_co")
        mov [origsp], esp       ; save callers stack top
        mov [curr], ebx         ; store current co-routine index
        jmp resume.cont         ; perform state-restoring part of "resume"

        ;; can be called or jumped to
end_co:
        mov esp, [origsp]       ; restore stack top of whoever called "start_co"
        popa                    ; restore all registers
        ret                     ; return to caller of "start_co"

        ;; ebx = co-routine index to switch to
resume:                         ; "call resume" pushed return address
        pushf                   ; save flags to source co-routine stack
        pusha                   ; save all registers
        xchg ebx, [curr]        ; ebx = current co-routine index
        mov [cors + ebx*4], esp ; update current co-routines stack top
        mov ebx, [curr]         ; ebx = destination co-routine index
.cont:
        mov esp, [cors + ebx*4] ; get destination co-routines stack top
        popa                    ; restore all registers
        popf                    ; restore flags
        ret                     ; jump to saved return address



make_a_beat:
; This function runs on all the courotines and applying the rules of the game.
        pop     edx ; its the j
        pop     eax ; its the i
.after_init:
        push    eax
        push    edx
        call    set_boundries
        call    check_neighbors
        push    ecx
        call    decide_fate
        add     esp, 12
        xor     ebx,ebx
        call    resume
        push    eax
        push    edx
        call    update_original_array
        add     esp,8
        xor     ebx,ebx
        call    resume
        jmp     .after_init
        


check_neighbors:
;this function checks the number of living neighbors, it gets i and j coordinate.
; in ECX it returns the number of living neighbors.
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        pusha
        mov     ebx, dword[ebp+12] ; i coordinate.
        mov     edx, dword[ebp+8] ; j coordinate.
        push    ebx
        push    edx
        call    set_boundries
        add     esp, 8

        ; now startX/Y and endX/Y are being seted for this cell.
        xor     ecx,ecx ;resets neighbors counter 
        xor     edi,edi ;resets loop indicator

.loop:
        ;first we will decide which neighbor we check.
        cmp     edi,0
        je      .set0
        cmp     edi,1
        je      .set1
        cmp     edi,2
        je      .set2
        cmp     edi,3
        je      .set3
        cmp     edi,4
        je      .set4
        cmp     edi,5
        je      .set5
        cmp     edi,6
        je      .set6
        cmp     edi,7
        je      .set7
        jmp     .end_loop

.set0:
        push    dword[startY]
        push    dword[startX]
        jmp     .continue
.set1:
        push    dword[startY]
        push    edx
        jmp     .continue
.set2:
        push    dword[startY]
        push    dword[endX]
        jmp     .continue
.set3:
        push    ebx
        push    dword[startX]
        jmp     .continue
.set4:
        push    ebx
        push    dword[endX]
        jmp     .continue
.set5:
        push    dword[endY]
        push    dword[startX]
        jmp     .continue
.set6:
        push    dword[endY]
        push    edx
        jmp     .continue
.set7:
        push    dword[endY]
        push    dword[endX]
        jmp     .continue
.continue:
        call    get_values_array                ; we get the right neighbor value to eax
        add     esp, 8
.break3:
        inc     edi
        cmp     eax, ' '
        je      .loop ; this neighbor is dead, what a waste of time.
        inc     ecx   ; this neighbor is alive, COUNTER HAS BEEN INCREASED
        jmp     .loop
.end_loop:
        mov     dword[ebp-4], ecx
        popa
        mov     ecx, dword[ebp-4]
        mov     esp, ebp
        pop     ebp
        ret




set_boundries:
        push    ebp
        mov     ebp, esp
        pusha
        mov     ebx, dword[ebp+12] ; i coordinate.
        mov     edx, dword[ebp+8] ; j coordinate.
        xor     eax,eax
        xor     ecx, ecx
        cmp     ebx, 0
        je      .set_special_startY
        mov     cl, byte[WorldLength]
        dec     cl
        cmp     bl, cl
        je      .set_special_endY
        jmp     .set_normal_Y
.set_special_startY:
        mov     cl, byte[WorldLength]
        dec     cl
        mov     dword[startY],  ecx
        mov     ecx, ebx
        inc     ecx
        mov     dword[endY], ecx
        jmp     .after_Y_seted
.set_special_endY:
        mov     ecx, ebx
        dec     ecx
        mov     dword[startY], ecx
        mov     dword[endY], 0
        jmp     .after_Y_seted
.set_normal_Y:
        mov     ecx, ebx
        dec     ecx
        mov     dword[startY], ecx
        add     ecx, 2
        mov     dword[endY], ecx
        jmp     .after_Y_seted

.after_Y_seted:
        cmp     edx, 0
        je      .set_special_startX
        mov     cl, byte[WorldWidth]
        dec     cl
        cmp     dl, cl
        je      .set_special_endX
        jmp     .set_normal_X

.set_special_startX:
        mov     cl, byte[WorldWidth]
        dec     cl
        mov     dword[startX],  ecx
        mov     ecx, edx
        inc     ecx
        mov     dword[endX], ecx
        jmp     .after_boundries_seted
.set_special_endX:
        mov     ecx, edx
        dec     ecx
        mov     dword[startX], ecx
        mov     dword[endX], 0
        jmp     .after_boundries_seted
.set_normal_X:
        mov     ecx, edx
        dec     ecx
        mov     dword[startX], ecx
        add     ecx, 2
        mov     dword[endX], ecx
        jmp     .after_boundries_seted
.after_boundries_seted:
        popa
        mov     esp, ebp
        pop     ebp
        ret

decide_fate: ; (i,j,number of living neighbors)
;this function decides the fate of the cell, and checks him in the new array, it gets i, j and number of living neighbors.
; it returns nothing.
; NOTE: the new value applied in THE TEMPORARY ARRAY
        push    ebp
        mov     ebp, esp
        pusha
        mov     ebx, dword[ebp+16] ; i coordinate
        mov     edx, dword[ebp+12] ; j coordinate
        mov     ecx, dword[ebp+8] ; number of living neighbors
        push    ebx
        push    edx
        call    get_values_array ; now eax has the value of the cell
        add     esp, 8
        cmp     eax, ' '
        je      .dead_cell
        ; else this cell is alive
        cmp     ecx, 3
        je      .inc_cell
        cmp     ecx, 2
        je      .inc_cell
        ;if we got here, that cell has to DIE.
        push    ebx
        push    edx
        push    ' '
        call    set_temporary_value
        add     esp, 12
        ; the cell is dead now, HIS FATE HAS BEEN DECIDED.
        jmp .end
.inc_cell:
        cmp     eax, '9'
        je      .end
        ; else, lower than 9 and should be increased.
        inc     eax
        push    ebx
        push    edx
        push    eax
        call    set_temporary_value
        add     esp, 12
        ; the cell will continue his life, with a +1 generation.
        jmp     .end
.dead_cell:
        cmp     ecx, 3
        jne     .stay_dead ; the cell doesnt have 3 living neighbors therefore he should stay dead
        ;if we got here, that cell has to COME ALIVE.
        push    ebx
        push    edx
        push    '1'
        call    set_temporary_value
        add     esp,12
        jmp     .end
.stay_dead:
        push    ebx
        push    edx
        push    ' '
        call    set_temporary_value
        add     esp,12
        jmp     .end
.end:
        popa
        mov     esp, ebp
        pop     ebp
        ret





update_original_array: ;this function just copy the temporary array to the original one.
; it gets none and returns none
        push    ebp
        mov     ebp, esp
        pusha
        mov     ebx,dword[ebp+12] ;ebx is the i
        mov     edx,dword[ebp+8]  ;edx is the j
        push    ebx
        push    edx
        call    get_temporary_value
        push    eax
        call    set_a_value
        add     esp,12
        popa
        mov     esp, ebp
        pop     ebp
        ret

set_temporary_value: ;gets i j and a value, and sets this value to coordinate i,j
        push    ebp
        mov     ebp, esp
        pusha
        xor     ecx,ecx
        mov     ebx, dword[ebp+16] ; i coordinate
        mov     edx, dword[ebp+12] ; j coordinate
        mov     cl, byte[WorldWidth]
        imul    ebx, ecx ; now ebx = i*width
        add     edx, temporary_array ; now ebx = startMatrix+i*width
        add     ebx, edx ; now ebx = startMatrix+i*width+j, so we are in the right courotine
        xor     eax, eax
        mov     ecx, dword[ebp+8] ; the value
        mov     byte[ebx], cl
        popa
        mov     esp, ebp
        pop     ebp
        ret

get_temporary_value: ; get i and j coordinates, and returns the VALUE of this corutine.
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        pusha
        xor     ecx,ecx
        mov     ebx, dword[ebp+12] ; i coordinate
        mov     edx, dword[ebp+8] ; j coordinate
        mov     cl, byte[WorldWidth]
        imul    ebx, ecx ; now ebx = i*width
        add     edx, temporary_array ; now ebx = startMatrix+i*width
        add     ebx, edx ; now ebx = startMatrix+i*width+j, so we are in the right courotine
        xor     eax, eax
        mov     al, byte[ebx]
        mov     dword[ebp-4], eax
        popa
        mov     eax, dword[ebp-4]
        mov     esp, ebp
        pop     ebp
        ret