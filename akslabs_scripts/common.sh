#!/bin/bash

SAP=$1

labs=$(ls $SAP)
lab_names=()
for lab in $labs; do
    name=$(echo $lab | sed 's/_/./' | sed 's/_/ /g')
    lab_names+=("${name::-3}")
done
# echo "${lab_names[@]}"
number_of_labs="${#lab_names[@]}"

sed "s/lab_names=.*/lab_names=$lab_names/" wrapper.sh
sed "s/number_of_labs=.*/number_of_labs=$number_of_labs/" wrapper.sh
