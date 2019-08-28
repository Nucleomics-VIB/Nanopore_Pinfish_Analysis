#!/bin/bash

gtf=$1
bed=$2
grep -v "^#" ${gtf} | \
	gawk 'BEGIN{FS="\t"; OFS="\t"}{if ($3=="exon") {split($9,id, ";"); gsub("gene_id \"","",id[1]); gsub("\"","",id[1]); print $1,$4-1,$5,id[1],$7}}' \
	| sort -k 1V,1,-k 2n,2 -k 3n,3 > ${bed}

