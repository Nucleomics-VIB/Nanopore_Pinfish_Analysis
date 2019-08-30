#!/bin/bash
# on linux, IGV is called by igv.sh
# and bash variables below derived from the config.yaml values
# getting yaml to bash variables can easily be done with parse_yaml from https://gist.github.com/pkuczynski/8665367

parse_yaml ()
{
    local prefix=$2;
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034');
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 | awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml config.yaml)

cmd="igv.sh -g ./ReferenceData/$(basename ${genome_fasta%.gz}) \
./Analysis/Minimap2/$(basename ${raw_fastq}).bam,\
./Analysis/Minimap2/polished_reads_aln_sorted.bam,\
./ReferenceData/$(basename ${genome_annot%.gz}),\
./Analysis/Pinfish/polished_transcripts.gff,\
./Analysis/GffCompare/nanopore.combined.gtf,\
./Analysis/GffCompare/class_=_nanopore.combined.gtf,\
./Analysis/GffCompare/class_u_nanopore.combined.gtf,\
./Analysis/MosDepth/gene_coverage.igv"

echo "# running ${cmd}"
eval ${cmd}
