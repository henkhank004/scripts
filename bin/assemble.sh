#!/bin/bash
# Uses nasm and ld to assemble and link an .asm files.
# The assembly files MUST end in ".asm".
# The object files MUST end in ".o".
#
# Possible exit codes set from this process:
#   0                   success
#   1                   no input files
#   2                   assembling failed
#   3                   linking failed

show_help() {
    echo "
        Usage: $0 [OPTIONS]

        Options:
            -h                  Display this help message and exit

            -l                  Automatically link all the object files,
                                if no output name is provided through output
                                flag (-o, --out), will use "a.out".

            -o                  Set a custom name for the outputted executable
                                only used if automatic linking flag is set
                                (-l, --link).

            -d                  Assmble and link with debugging symbols, passes
                                [-g -F dwarf] flags to nasm
                                and [-g] flag to ld.
    "
    exit 0
}

# Initialise standard options
link=false
debug=false
output="a.out"

# Process the options
while getopts "o:ldh" opt; do
    case "$opt" in
        h) show_help ;;
        l) link=true ;;
        o) output=$OPTARG ;;
        d) debug=true ;;
        ?) echo "Invalid option use -h for help" ;;
    esac
done

# Check for appropriate directories, create them if not present
if [ $debug = true ]; then
    if [ ! -d "./debug" ]; then
        mkdir ./debug
        mkdir ./debug/obj
    else
        if [ ! -d "./debug/obj" ]; then
            mkdir ./debug/obj
        fi
    fi
else
    if [ ! -d "./obj" ]; then
        mkdir ./obj
    fi
fi

# Find the asm and obj files passed as args.
asm_files=()
obj_files=()
for arg in $@; do
    if [[ $arg == *.asm ]]; then    
        asm_files+=($arg)
    else
        if [[ $arg == *.o ]]; then
            obj_files+=($arg)
        fi
    fi
done

if [ ${#asm_files[@]} -eq 0 ] && [ ${#obj_files[@]} -eq 0 ]; then
    echo "No input file(s)"
    exit 1
fi

# Assemble the as files into obj files
for file in ${asm_files[@]}; do
    if [ $debug == true ]; then
        obj_name="${file%.asm}_debug.o"
        nasm -f elf64 -g -F dwarf "$file" -o "./debug/obj/$obj_name" || { echo "Assembly failed for '$file', nasm exit code $?"; exit 2; }
        obj_files+=("./debug/obj/$obj_name")
    else
        obj_name="${file%.asm}.o"
        nasm -f elf64 "$file" -o "./obj/$obj_name" || { echo "Assembly failed for '$file', nasm exit code $?"; exit 2; }
        obj_files+=("./obj/$obj_name")
    fi
done

# Link the files
if [ $link == true ]; then
    if [ $debug == true ]; then
        ld -g ${obj_files[@]} -o "$output" || { echo "Linking failed, ld exit code $?"; exit 3; }
    else
        ld ${obj_files[@]} -o "$output" || { echo "Linking failed, ld exit code $?"; exit 3; }
    fi
fi
