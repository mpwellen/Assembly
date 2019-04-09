;;; layout of the structure
%define TITLE_OFFSET 0
%define AUTHOR_OFFSET 48
%define PRICE_OFFSET 96
%define YEAR_OFFSET 104
%define NEXT_OFFSET 112

;;; our usual system call stuff
%define STDOUT 1
%define SYSCALL_EXIT  60
%define SYSCALL_WRITE 1

    SECTION .data
;;; Here we declare initialized data. For example: messages, prompts,
;;; and numbers that we know in advance

newline:        db 10

    SECTION .bss
;;; Here we declare uninitialized data. We're reserving space (and
;;; potentially associating names with that space) that our code
;;; will use as it executes. Think of these as "global variables"

    SECTION .text
;;; This is where our program lives.
global _start                               ; make start global so ld can find it
extern library
global authorsForPrice

printNewline:
        push rax
        push rbx
        push rcx
        push rdx
        push rsi

        mov rax, SYSCALL_WRITE
        mov rdi, STDOUT
        mov rsi, newline
        mov rdx, 1
        syscall

        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

;;; rax should point to the string. on return, rax is the length
stringLength:
;;; Students: Feel free to use this code in your submission but you
;;; must add comments explaining the code to prove that you
;;; know how it works.

        push rsi 		;saves rsi, and moves rax to rsi
        mov rsi, rax		;moves the rax to rsi
        mov rax, 0		;Sets the initial lenght to be 0

loopsl:
        cmp [rsi], byte 0	;If the contents of rsi are 0, then the string length has been calculated
        je endsl	

        inc rax			;Otherwise, increment the address and the length value.
        inc rsi
        jmp loopsl

endsl:
        pop rsi			;returns the rsi value to the register 
        ret			;returns to print name

;;; this label will be called as a subroutine by the code in driver.asm
authorsForPrice:
        ;; protect the registers we use, and then moves the first record to rsi. 

        push rax
        push rbx
        push rcx
        push rdx
        push rsi

        ;; Loads the first record in the library to rsi.
        mov rsi,[library]
	mov r14,0
loop1:
        ;; Check the price record of the current record. If its greater than the test vlalue, then prints name.
	;; If the "NEXT" value is 0, then removes test value from float stack, and recovers registers from float stack.
	;; If the "NEXT" value is not zero, then just jumps to the updateRSI so that the next record can be checked.

	;; Registers
	;; rsi contains the "base" address for the record
	;; r12 is used to get the price value from the record

	;; Float Registers
	;; At the start of this script, st0 contains the filter value to be tested against.
	
        add r14,1
	mov r12,rsi 		;moves the record address to r12
        add r12,PRICE_OFFSET 	;Moves r12 to the price address
        fld qword[r12]		;Loads to the floating point register
        fcomip st0,st1		;Compares the price to the price that was there from driver.asm. Then pops result of comparison
        ja printName		;If flags indicate (recordPrice>testPrice), then print the values for that record
	add rsi,NEXT_OFFSET     ;else, skip and get the next record from the NeXT_OFFSET
        cmp dword[rsi],0	
	jne updateRSI 		;If the Next is not 0, update the rsi to the next record

	;; If it is zero, then clean up and move to next test
	fstp st0		 ;Remove the test value from the floating point stack ;
	pop rsi			;Return the register values in the stack to the registers
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret			;Returns to driver.asm to use next filter
        
printName:

        lea rax, [rsi + AUTHOR_OFFSET]  ; Load-Effective-Address computes the address in
                                        ; the brackets and returns it instead of looking it up.

        call stringLength               ; after this, RAX will have the length of the author name

        mov rdx, rax                    ; copy it to the count register for the system call
        mov rax, SYSCALL_WRITE
        mov rdi, STDOUT
        lea rcx, [rsi + AUTHOR_OFFSET]
        push rsi                        ; preserve RSI
        mov rsi, rcx
        syscall

        pop rsi                         ; restore RSI
			
        call printNewline
        
cleanUp:
;;; If the next value has an address, then will jump back to the loop1
;;; If the next value is null (0), then pop test value from float stack, return the stack  values to the register, and return to driver.asm. In other words, cleanUp
	add rsi,NEXT_OFFSET	;Check the next offset
	cmp dword[rsi],0	;if 0, then you're done. 
	jne updateRSI		;otherwise, update the RSI and go back to loop
	fstp st0		;Removes the test value from the float stack.
        pop rsi			;Get your values back from the stack
        pop rdx
        pop rcx
        pop rbx
        pop rax
        
        ret			;returns to driver.asm

updateRSI:
;;; Utiity function to move rsi to the next record, based on the "NEXT" value of the current one.
	mov r15,[rsi]		;moves the "NEXT" address to r15, then moves it to rsi. 
	mov rsi,r15
	jmp loop1		;then jmp to loop1 to repeat
	
