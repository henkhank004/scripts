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
                                flag (-o) will use "a.out".

            -o                  Set a custom name for the outputted executable
                                only used if automatic linking flag (-l)
                                is set. 

            -d                  Assemble and link with debugging symbols, 
                                passes [-g -F dwarf] flags to nasm
                                and [-g] flag to ld.

            -r                  Run the executable when assembling and linking
                                is done. Does nothing if automatic linking flag
                                is not set.
    "
    exit 0
}

# Initialise standard options
link=false
debug=false
run=false
output="a.out"

# Process the options
while getopts "hlo:dr" opt; do
    case "$opt" in
        h) show_help ;;
        l) link=true ;;
        o) output=$OPTARG ;;
        d) debug=true ;;
        r) run=true ;;
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


# DEBUG
#for file in ${asm_files[@]}; do
#    base=$(basename $file)
#    obj_name="${base%.asm}_debug.o"
#    echo $obj_name
#done
#exit 0


# Assemble the as files into obj files
for file in ${asm_files[@]}; do
    if [ $debug == true ]; then
        base=$(basename $file)
        obj_name="${base%.asm}_debug.o"
        nasm -f elf64 -g -F dwarf "$file" -o "./debug/obj/$obj_name" || { exit 2; }
        obj_files+=("./debug/obj/$obj_name")
    else
        base=$(basename $file)
        obj_name="${base%.asm}.o"
        nasm -f elf64 "$file" -o "./obj/$obj_name" || { exit 2; }
        obj_files+=("./obj/$obj_name")
    fi
done

# Link the files
if [ $link == true ]; then
    if [ $debug == true ]; then
        ld -g ${obj_files[@]} -o "./debug/$output" || { echo "Linking failed, ld exit code $?"; exit 3; }
    else
        ld ${obj_files[@]} -o "$output" || { echo "Linking failed, ld exit code $?"; exit 3; }
    fi
fi

if [ $run == true ]; then
    if [ $debug == true ]; then
        ./debug/$output
        echo "Exit code: $?"
    else
        ./$output
        echo "Exit code: $?"
    fi
fi
