#!/bin/bash

# Define file names
source="labels_io.asm"
object="labels_io.o"
executable="labels_io"

# Assemble the .asm file for 64-bit architecture
nasm -f elf64 "$source" -o "$object"

# Link the object file using gcc, which automatically links against glibc
gcc -nostartfiles -no-pie -o "$executable" "$object"

# Run the executable
./"$executable"
