#!/bin/bash
echo "Bash version ${BASH_VERSION}..."

for i in $(seq -f "%04g" 0 10)
do
	echo "iteration: " ${i}
	python download-scannet.py -o ./ --id scene${i}_00
done

