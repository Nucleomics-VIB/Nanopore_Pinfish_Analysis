#!/bin/bash

# filter nanopore.combined.gtf file and use lines with class $2 to create a new gff for IGV

gtf=$1
fname=$(basename ${gtf})
pname=$(dirname ${gtf})
class=$2
q="class_code \"${class}\""

echo "# filtering '${q}'"

# get list of IDs
gawk -v cl="${q}" 'BEGIN{FS="\t"; OFS="\t"}{ split($9,anno,";"); if ( anno[4]~cl || anno[6]~cl ) { split(anno[1],id,"\""); sel[id[2]]=1 } }END{for (x in sel) {print x} }' ${gtf} > /tmp/selected.lst

# extract
grep -f /tmp/selected.lst ${gtf} > "${pname}/class_${class}_${fname}"
