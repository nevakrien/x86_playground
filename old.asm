section .data
    prompt db "Enter input: ", 0
    prompt_len equ $ - prompt
    overflow_msg db "ERROR: input too large", 0xA, 0
    overflow_msg_len equ $ - overflow_msg
    input_cap equ 4096

    malloc_fail_msg db "went OOM...", 0xA, 0
    malloc_fail_msg_len equ $ - overflow_msg

section .bss
    ; Uninitialized data
    input resb input_cap  ; Reserve buffer for input

section .text
    extern malloc
    extern free
    extern memcpy
    global _start


align 16
_start:
main_loop:
    ;Write a prompt to stdout
    mov ebx, 1            ; stdout
    mov eax, 4            ; sys_write
    mov ecx, prompt       ; message to print
    mov edx, prompt_len   ; message length
    int 0x80

    ; Read from stdin into input
    mov eax, 3              ; system call number for sys_read
    mov ebx, 0              ; file descriptor 0 is stdin
    mov ecx, input          ; buffer to store input
    mov edx, input_cap  ; number of bytes to read
    int 0x80                ; make kernel call

    ;overflow check
    cmp eax, input_cap;
    jz say_overflow
    
    ;save input size so we can use later
    push dword eax

    ;show input
    ;Output the received input
    mov edx, eax          ; number of bytes to write
    mov eax, 4            ;write
    mov ebx, 1            ; stdout
    int 0x80
    
    ;get memory
    call malloc
    test eax, eax           ; Check if malloc failed (eax == 0)
    jz allocation_failed
    
    ;save buffer metadata
    pop ebx 
    ;mov esi, ebx
    mov edi, eax

    ; Perform memory copy
    mov ecx, input          ; Source buffer
    mov edx, eax            ; Destination buffer (malloc'ed memory)
    mov eax, ebx            ; Number of bytes to copy
    call memcpy

    jmp main_loop

say_overflow:
    ;empty out all of stdin
    mov eax, 3
    int 0x80
    cmp eax, input_cap;
    jz say_overflow

    ; Print overflow message
    mov eax, 4
    mov ebx, 1
    mov ecx, overflow_msg
    mov edx, overflow_msg_len
    int 0x80

    jmp _start

allocation_failed:
    mov eax, 4            ; sys_write
    mov ecx, malloc_fail_msg       ; message to print
    mov edx, malloc_fail_msg_len   ; message length
    int 0x80

exit:
    ; Exit the program
    mov eax, 1              ; system call number for sys_exit
    xor ebx, ebx            ; exit status 0
    int 0x80                ; make kernel call