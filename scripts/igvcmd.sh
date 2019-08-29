#!/bin/bash

. ~/.bash_functions
eval $(parse_yaml config.yaml)

cmd="igv.sh -g ./ReferenceData/$(basename ${genome_fasta%.gz}) \
./Analysis/Minimap2/$(basename ${raw_fastq}).bam,\
./Analysis/Minimap2/polished_reads_aln_sorted.bam,\
./ReferenceData/$(basename ${genome_annot%.gz}),\
./Analysis/Pinfish/polished_transcripts.gff,\
./Analysis/MosDepth/gene_coverage.igv"

echo "# running ${cmd}"
eval ${cmd}
