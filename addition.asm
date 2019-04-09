;
; Assemble using NASM
;
        SECTION .data                   ; Data section

msg:    db "Program Executed", 10       ; The string to print when complete.
len:    equ $-msg

        SECTION .text                   ; Code section.
        global _start
_start: nop                             ; Entry point.
        mov     esi, 0xA0000000         ; First number
        mov     edi, esi                ; Copy to r10
        add     edi, esi                ; Perform addition
        mov     edx, len                ; Arg 3: length of string.
        mov     ecx, msg                ; Arg 2: pointer to string.
        mov     ebx, 1                  ; Arg 1: file descriptor.
        mov     eax, 4                  ; Write.
        int     080H

        mov     ebx, 0                  ; exit code, 0=normal
        mov     eax, 1                  ; Exit.
        int     080H                    ; Call kernel.
