#!/bin/bash
# Uses nasm and ld to assemble and link an .asm files.
# Assumes first argument is the name.
# Assumes the first file name as the output name if no name is specified.

FILES=("$@")
MANUAL_LINKING=false
for FILE in "${FILES[@]}"; do
    if [[ "$FILE" == "-nl" || "$FILE" == "--nolink" ]]; then
        MANUAL_LINKING=true
        FILES=("${FILES[@]:1}")
    fi
done

OUTPUT_NAME="$1"
if [[ "$1" == *.asm ]]; then
    OUTPUT_NAME="${1%.asm}_debug"
else
    if [[ "$1" == *.o ]]; then
        OUTPUT_NAME="${1%.o}_debug"
    else
        FILES=("${FILES[@]:1}")
    fi
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No input file(s)."
    exit 1
fi

if [ ! -d "./obj_debug" ]; then
    mkdir ./obj_debug
fi

OBJ_FILES=()
for FILE in "${FILES[@]}"; do
    if [[ "$FILE" == *.asm ]]; then
        OBJ_FILE="${FILE%.asm}_debug.o"
        nasm -f elf64 -g -F dwarf "$FILE" -o "./obj_debug/$OBJ_FILE" || { echo "Assembly failed for '$FILE'"; exit 2; }
        OBJ_FILES+=("./obj_debug/$OBJ_FILE")
    else
        if [[ "$FILE" == *.o ]]; then
            OBJ_FILES+=("$FILE")
        else
            echo "Could not determine whether '$FILE' is an assembly file or an object file; discarding."
        fi
    fi
done

if [ $MANUAL_LINKING == false ]; then
    ld -g "${OBJ_FILES[@]}" -o "$OUTPUT_NAME" || { echo "Linking failed."; exit 3; }
fi

