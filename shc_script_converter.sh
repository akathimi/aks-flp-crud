#!/bin/bash

## Script to convert the base lab scripts to binaries
shell_path=akslabs_scripts/labs_sh
SHC_STATUS=$(which shc > /dev/null; echo $?)
if [ "$SHC_STATUS" -ne 0 ]
then
    echo -e "\nError: missing shc binary...\n"
    exit 4
fi

AKSLABS_SCRIPTS="$(ls $shell_path)"
if [ -z "$AKSLABS_SCRIPTS" ]
then
    echo -e "Error: missing akslabs scripts...\n"
    exit 5
fi

function convert_to_binary() {
    SCRIPT_NAME="$1"
    BINARY_NAME="$(echo "$SCRIPT_NAME" | sed 's/.sh//')"
    shc -f $shell_path/"${SCRIPT_NAME}" -r -o ./akslabs_binaries/"${BINARY_NAME}"
    rm -f $shell_path/"${SCRIPT_NAME}".x.c > /dev/null 2>&1
}

for FILE in $(echo "$AKSLABS_SCRIPTS")
do
    convert_to_binary "$FILE"
done

exit 0
