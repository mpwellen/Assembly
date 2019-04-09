; File: textSearch.asm
;
; This program demonstrates the use of an indexed addressing mode
; to access data within a record
;
; Assemble using NASM:  nasm -f elf64 textSearch.asm
; Link with ld:  ld textSearch.o -o textSearch
;

%define STDIN         0
%define STDOUT        1
%define SYSCALL_EXIT  60
%define SYSCALL_READ  0
%define SYSCALL_WRITE 1
%define BUFLEN        100

        SECTION .data                                   ; Data section
msg1:   db "Enter search string: "                      ; user prompt
len1:   equ $-msg1                                      ; length of message

msg2:   db 10, "Read error", 10                         ; error message
len2:   equ $-msg2                                      ; length of error message

msg3a:  db "Text you searched, appears at  "            ; String found message
len3a:  equ $-msg3a                                     ; length of message

msg3b:	db " characters after the first."               ; Remainder of string found message
len3b:	equ $-msg3b					; length of message

msg4:   db "String not found!", 10                      ; string not found message
len4:   equ $-msg4                                      ; length of message

endl:	db 10						; Linefeed

                                                        ; simulates a text file (record)
record:
row1:   db "Knight Rider a shadowy flight"
row2:   db "into the dangerous world of a"
        db " man who does not exist. Mich"
        db "ael Knight, a young loner on "
        db "a crusade to champion the cau"
        db "se of the innocent, the innoc"
        db "ent, the helpless in a world "
        db "of criminals who operate abov"
        db "e the law. Knight Rider, Keep"
        db " riding brave into the night."
rlen:   equ $-record
rowlen: equ row2 - row1

        SECTION .bss                                    ; uninitialized data section
buf:    resb BUFLEN                                     ; buffer for read
loc:    resb BUFLEN                                     ; buffer to store found location string
count:  resb 4                                          ; reserve storage for user input bytes

        SECTION .text                                   ; Code section.
        global _start
_start: nop                                             ; Entry point.

                                                        ; prompt user for input
                                                        ;
        mov rax, SYSCALL_WRITE                          ; write function
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, msg1                                   ; Arg2: addr of message
        mov rdx, len1                                   ; Arg3: length of message
        syscall                                         ; 64-bit system call

                                                        ; read user input
                                                        ;
        mov rax, SYSCALL_READ                           ; read function
        mov rdi, STDIN                                  ; Arg1: file descriptor
        mov rsi, buf                                    ; Arg2: addr of message
        mov rdx, BUFLEN                                 ; Arg3: length of message
        syscall                                         ; 64-bit system call

                                                        ; error check
                                                        ;
        mov [count], rax                                ; save length of string read
        cmp rax, 0                                      ; check if any chars read
        jg  read_OK                                     ; >0 chars read = OK
        mov rax, SYSCALL_WRITE                          ; Or Print Error Message
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, msg2                                   ; Arg2: addr of message
        mov rdx, len2                                   ; Arg3: length of message
        syscall                                         ; 64-bit system call
        jmp     exit                                    ; skip over rest

read_OK:                                                ; Input was accepted, now initialize
       	mov rax,record					;move the address of the first record character  to rax
        mov rbx,buf					;move the address of the first input character to rbx
	mov r14,0					;r14 is used to store the counter for the input string. This line initializes this vale to 0.
	mov r13,0					;r13 is used to store the counter for the record. This line initializes this value to 0.
	mov r12,[count]					;r12 is used to store the length of the input string.
	sub r12,1					;1 is subtracted from r12 to set it to a proper initial value for use by the loop.
	mov r8b,[rax]					;stores the character within the current record character  address to r8b.
	mov r9b,[rbx]					;stores the character within the current input address to r9b
        jmp outside_While				;jumps to outside_While

outside_While:
			
	cmp r14,rlen	; compares the record counter to the length of the record. 
	ja  nope	; If above the length of the record, it means the entire record has been checked for the input substring.
	mov rbx,buf	; moves the address of the first character of the input to rbx
	mov r13,0	; sets the input counter to 0
	cmp r8b,r9b	; compares the first character of the input string with the current character of the record string
	je  inside_While	;If they're equal, go to inside_While.
	add rax,1		;Increment the address containing the current character to the one containing the  next character
	add r14,1		;Increment the record counter
	mov r8b,[rax]		;store the character within the (now) current character address point to r8b
	mov r9b,[rbx]		;stores the first character of the input string to r9b
	jmp outside_While	;jumps to beginning of outside_While
			

inside_While:
	add rax,1		;increments the current record-character address to point to the next character in the record.
	add rbx,1		;increments the current input-character address to point to teh next character in the input string
	add r13,1		;increments the input coutner
	mov r8b,[rax]		;stores current record-characgter to r8b
	mov r9b,[rbx]		;stores current input-character to r9b
	cmp r13,r12		;Checks if number of matching characters matches length of input
	je  found		;if so, substring was found
	cmp r8b,r9b		;Checks if characters are equal
	je  inside_While	;if so, jump back to beginning of inside_While
	sub rax,r13		;If not, then set the database address back to point immediately after the first matching character
	mov r8b,[rax]		;Stores current record character to r8b
	mov r9b,[rbx]		;Stores initial input character to r9b
	jmp outside_While	;Jumps back to outside_While

init:                                                   ; Regsiter initializations. I didn't use this in my program. 

found:                                                  ; If string was found print location
                                                        ; Following is a snippet of code for
                                                        ; printing out the digits of a number if its more 
                                                        ; than one digit long
        mov     r10, 1                                  ; Keeps track of the number of digits to be printed
        mov     rdi, loc                                ; Store the address of location buffer
        mov	rax,r14	 				; Moves record counter (found in outside_While) to rax for reporting.
        mov     cl, 10                                  ; Print out its digits using a loop
        cmp     ax, 9                                   ; Is the number larger than a single digit?
        jg      digits                                  ; if so, jump to store the digits routine
        mov     rbx, rax                                ; Copy the value into rbx (Used later by a shifting out routine)
        add     bl, '0'                                 ; Add the ASCII character offset for numbers
        jmp     shOut                                   ; Shift out routine

digits:	div	cl                                      ; Divide by 10  (212/10 , Quotient (AH) - 21, Remainder (AL) - 2)
                                                        ; ... On the first iteration of this loop                          
	mov	bl, ah                                  ; Store the remainder in bl
	add	bl, '0'                                 ; Add the ASCII character offset for numbers
	shl	rbx, 8                                  ; Shift left the character, so that they can be shifted out in reverse 
	and 	ax, 0x00FF                              ; Clear out the remainder from the result
	inc	r10                                     ; R10 keeps track of the number of digits
	cmp	al, 0                                   ; See if we have any more digits to convert
	jnz	digits                                  ; If there are more, keep looping

shOut:
	mov	[rdi], bl                               ; move the first digit (now a character) into destination
	inc	rdi                                     ; update to next character position
	shr	rbx, 8                                  ; Shift out the next digit
	cmp	bl, 0                                   ; Check to see if we have shifted out all digits
	jnz	shOut                                   ; More digits? Keep looping

        mov rax, SYSCALL_WRITE                          ; Print Message
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, msg3a                                  ; Arg2: addr of message
        mov rdx, len3a                                  ; Arg3: length of message
        syscall                                         ; 64-bit system call


        mov rax, SYSCALL_WRITE                          ; Write out location information
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, loc                                    ; Arg2: addr of message
        mov rdx, r10                                    ; Arg3: length of message
        syscall                                         ; 64-bit system call

        mov rax, SYSCALL_WRITE                          ; Print remainder of Message
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, msg3b                                  ; Arg2: addr of message
        mov rdx, len3b                                  ; Arg3: length of message
        syscall                                         ; 64-bit system call

        mov rax, SYSCALL_WRITE                          ; Write out string
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, endl                                   ; Arg2: addr of message
        mov rdx, 1                                      ; Arg3: length of message
        syscall                                         ; 64-bit system call

        jmp exit

nope:                                                   ; String not found message
                                                        ;
        mov rax, SYSCALL_WRITE                          ; Print Message
        mov rdi, STDOUT                                 ; Arg1: file descriptor
        mov rsi, msg4                                   ; Arg2: addr of message
        mov rdx, len4                                   ; Arg3: length of message
        syscall                                         ; 64-bit system call


exit:   mov rax, SYSCALL_EXIT                           ; exit system call id
        mov rdi, 0                                      ; exit to shell
        syscall
