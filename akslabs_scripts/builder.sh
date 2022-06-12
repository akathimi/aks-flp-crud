#!/bin/bash

SAP=$1
out_file="$SAP.sh"

labs=$(ls -x "$SAP")
sed -e "s/labs=.*/labs=(${labs[*]})/" main.sh > tmp_file

cat "$SAP"/* tmp_file | sed 's|#!/bin/bash||g' | sed '1s|^|#!/bin/bash|'> "$out_file"
rm -f tmp_file

