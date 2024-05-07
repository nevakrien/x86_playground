#!/bin/bash

# Define file names
source="labels_io.asm"
object="labels_io.o"
executable="labels_io.out"

# Assemble the .asm file
nasm -f elf "$source"

# Link the object file
ld -m elf_i386 -s -o "$executable" "$object"

# Run the executable
./"$executable"
