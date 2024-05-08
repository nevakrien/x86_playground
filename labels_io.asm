section .data
    prompt db 0xA, "Enter input: ", 0
    prompt_len equ $ - prompt
    overflow_msg db "ERROR: input too large", 0xA, 0
    overflow_msg_len equ $ - overflow_msg
    input_cap equ 4096

    malloc_fail_msg db "went OOM...", 0xA, 0
    malloc_fail_msg_len equ $ - malloc_fail_msg

    arow_str db " -> ", 0
    arow_str_len equ $ - arow_str


section .bss
    input resb input_cap  ; Reserve buffer for input

section .text
    extern malloc
    extern free
    extern memcpy
    global _start

_start:
;r12 holds size of malloced memory
;r13 holds a pointer to that memory
mov r12,0
mov r13,0

align 16
main_loop:
    ;show existing stuff
    mov r14,r13 
show_loop:
    test r14,r14
    je IO


    mov rdi, 1              ; stdout
    mov rax, 1              ; sys_write
    lea rsi, [r14 + 16]  ; message to print
    mov rdx, [r14 + 8]      ; message length
    sub rdx,1
    syscall


    mov rdi, 1              ; stdout
    mov rax, 1              ; sys_write
    mov rsi, arow_str         ; message to print
    mov rdx, arow_str_len     ; message length
    syscall

    mov r14,[r14] ;h=h->bext

    jmp show_loop

IO:
    ; Write a prompt to stdout
    mov rdi, 1              ; stdout
    mov rax, 1              ; sys_write
    mov rsi, prompt         ; message to print
    mov rdx, prompt_len     ; message length
    syscall

    ; Read from stdin into input
    mov rax, 0              ; system call number for sys_read
    mov rdi, 0              ; file descriptor 0 is stdin
    mov rsi, input          ; buffer to store input
    mov rdx, input_cap      ; number of bytes to read
    syscall

    ; Overflow check
    cmp rax, input_cap
    je say_overflow
    
    ; Save input size so we can use later
    mov r12, rax

    ; ; Output the received input
    ; mov rdx, rax            ; number of bytes to write
    ; mov rax, 1              ; write
    ; mov rdi, 1              ; stdout
    ; syscall
    
    ; Get memory
    lea rdi, [r12 + 16]
    call malloc
    test rax, rax           ; Check if malloc failed (rax == 0)
    jz allocation_failed
    
    ;append to the list
    mov [rax], r13 ;h->next=old_h
    mov [rax+8], r12 ;h->size=size
    mov r13, rax

    ; Perform memory copy
    lea rdi, [rax+16]            ;dest
    mov rsi, input          ; Source buffer
    mov rdx, r12            ; Number of bytes to copy
    call memcpy

    jmp main_loop

say_overflow:
    ; Empty out all of stdin
    mov rax, 0
    syscall
    cmp rax, input_cap
    je say_overflow

    ; Print overflow message
    mov rax, 1
    mov rdi, 1
    mov rsi, overflow_msg
    mov rdx, overflow_msg_len
    syscall

    jmp _start

allocation_failed:
    mov rax, 1              ; sys_write
    mov rsi, malloc_fail_msg       ; message to print
    mov rdx, malloc_fail_msg_len   ; message length
    syscall

exit:
    ; Exit the program
    mov rax, 60             ; system call number for sys_exit
    xor rdi, rdi            ; exit status 0
    syscall
