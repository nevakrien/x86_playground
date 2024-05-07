;basic example from chatgpt
section .data
    prompt db "Enter input: ", 0
    prompt_len equ $ - prompt
    overflow_msg db "Warning: Potential buffer overflow detected.", 0xA, 0
    overflow_msg_len equ $ - overflow_msg

section .text
    global _start

_start:
    ; Allocate memory on the heap using brk system call
    mov eax, 45           ; sys_brk
    mov ebx, 0            ; get current break location
    int 0x80
    mov ebx, eax          ; store current break in ebx
    add ebx, 256          ; request an increase by 256 bytes
    mov eax, 45           ; sys_brk
    mov ecx, ebx          ; set the new break
    int 0x80
    mov [heap_space], eax ; store new break location

    ; Write a prompt to stdout
    mov eax, 4            ; sys_write
    mov ebx, 1            ; stdout
    mov ecx, prompt       ; message to print
    mov edx, prompt_len   ; message length
    int 0x80

    ; Read from stdin into heap allocated space
    mov eax, 3            ; sys_read
    mov ebx, 0            ; stdin
    mov ecx, [heap_space] ; buffer to store input
    mov edx, 255          ; number of bytes to read
    int 0x80
    mov [input_len], eax  ; save the length of the input

    ; Check for buffer overflow (if the last character is not null)
    mov eax, [heap_space]
    add eax, 254          ; address of the last byte in the buffer
    cmp byte [eax], 0     ; compare last byte to null
    jz no_overflow

    ; Output overflow warning message
    mov eax, 4            ; sys_write
    mov ebx, 1            ; stdout
    mov ecx, overflow_msg ; warning message to print
    mov edx, overflow_msg_len ; message length
    int 0x80

no_overflow:
    ; Output the received input
    mov eax, 4            ; sys_write
    mov ebx, 1            ; stdout
    mov ecx, [heap_space] ; buffer to write from
    mov edx, [input_len]  ; number of bytes to write
    int 0x80

    ; Exit the program
    mov eax, 1            ; sys_exit
    xor ebx, ebx          ; status 0
    int 0x80

section .bss
    heap_space resd 1      ; Reserve space for heap memory address
    input_len resd 1       ; Reserve space for input length
