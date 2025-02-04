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
    OUTPUT_NAME="${1%.asm}"
else
    if [[ "$1" == *.o ]]; then
        OUTPUT_NAME="${1%.o}"
    else
        FILES=("${FILES[@]:1}")
    fi
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No input file(s)."
    exit 1
fi

if [ ! -d "./obj" ]; then
    mkdir ./obj
fi

OBJ_FILES=()
for FILE in "${FILES[@]}"; do
    if [[ "$FILE" == *.asm ]]; then
        OBJ_FILE="${FILE%.asm}.o"
        nasm -f elf64 "$FILE" -o "./obj/$OBJ_FILE" || { echo "Assembly failed for '$FILE'"; exit 2; }
        OBJ_FILES+=("./obj/$OBJ_FILE")
    else
        if [[ "$FILE" == *.o ]]; then
            OBJ_FILES+=("$FILE")
        else
            echo "Could not determine whether '$FILE' is an assembly file or an object file; discarding."
        fi
    fi
done

if [ $MANUAL_LINKING == false ]; then
    ld "${OBJ_FILES[@]}" -o "$OUTPUT_NAME" || { echo "Linking failed."; exit 3; }
fi

