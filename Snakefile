# Pinfish tutorial Snakefile

import os
import re
from snakemake.remote.HTTP import RemoteProvider as HTTPRemoteProvider

HTTP = HTTPRemoteProvider()

configfile: "config.yaml"

# assess the genome annotations ...
ProvidedGenomeFastaLink = config["genome_fasta"]
ProvidedAnnotationLink  = config["genome_annot"]
ProvidedBarcodesLink  = config["barcodes_fasta"]

# is fasta link is on filesystem; if URL then download - look for leading https / http / ftp ...

downloadSource = {}

ReferenceData = "ReferenceData"

def checkExternalLinks(xlink):
  yfile = xlink
  downloadSource[yfile]="nanoporetech.com"
  p = re.compile("(^http:|^ftp:|^https:)")
  if (p.search(xlink)):
    yfile = os.path.basename(xlink)
    ylink = re.sub("^[^:]+://", "", xlink)
    downloadSource[yfile]=ylink
  return yfile

GenomeFasta = checkExternalLinks(ProvidedGenomeFastaLink)
GenomeGFF = checkExternalLinks(ProvidedAnnotationLink)
BarcodesFasta = checkExternalLinks(ProvidedBarcodesLink)

unzipDict = {}
def handleExternalZip(xfile):
  yfile = re.sub("\.gz$","",xfile)
  if (yfile != xfile):
    unzipDict[yfile]=xfile
  return yfile

UnpackedReferenceFasta = handleExternalZip(GenomeFasta)
UnpackedGenomeGFF = handleExternalZip(GenomeGFF)

### 
# consider the unzip/bunzip required for e.g. the Pychopper analysis ...
unzipInt = {}
def handleInternalZip(xfile):
  p = re.compile("(\.zip$|\.bz2$|\.gz$)")
  yfile = p.sub("",xfile)
  if (yfile != xfile):
    unzipInt[yfile]=xfile
  return yfile

RawFastq = config["raw_fastq"]
UnpackedRawFastq = handleInternalZip(RawFastq)

# predicted MosDepth outputs
mos_out = ['gt0.mosdepth.global.dist.txt', 'gt0.mosdepth.region.dist.txt', 'gt0.per-base.bed.gz', 'gt0.per-base.bed.gz.csi', 'gt0.regions.bed.gz', 'gt0.regions.bed.gz.csi']


rule all:
  input:
    "Analysis/Pinfish/corrected_transcriptome_polished_collapsed.fas",
    "Analysis/Pinfish/clustered_transcripts_collapsed.gff",
    "Analysis/GffCompare/nanopore.combined.gtf",
    "ReferenceData/"+UnpackedGenomeGFF+"_exons.bed",
    "Analysis/Pinfish/plot_gffcmp_stats.png",
    expand("Analysis/MosDepth/{mos_out}", mos_out=mos_out),
    "Static/Images/graph.png",
    "Nanopore_Pinfish_Analysis.html"


rule DownloadRemoteFile:
  input: lambda wildcards: HTTP.remote(downloadSource[wildcards.downloadFile])
  output:
    "ReferenceData/{downloadFile}"
  shell:
    'mv {input} {output}'


rule UnpackPackedFile:
  input: lambda wildcards: ("ReferenceData/"+unzipDict[wildcards.unzipFile])
  output:
    "ReferenceData/{unzipFile}"
  shell:
    #"gunzip --keep -d {input}" --keep is obvious by missing from e.g. Centos 7
    "gunzip -c {input} > {output}"


rule Minimap2Index: ## build minimap2 index
    input:
        genome = "ReferenceData/"+UnpackedReferenceFasta
    output:
        index = "Analysis/Minimap2/"+UnpackedReferenceFasta+".mmi"
    params:
        opts = config["minimap_index_opts"]
    threads: config["threads"]
    shell:
      "minimap2 -t {threads} {params.opts} -I 1000G -d {output.index} {input.genome}"

# not sure why but snakemake passes some unexpected values into this wildcard - if the value
# is not in the starting dictionary then return an empty string
def getzipfile(wildcards):
  if (wildcards.unzipIntFile in list(unzipInt)):
    return "RawData/"+unzipInt[wildcards.unzipIntFile]
  return ""


rule UnpackFastqData: ## gunzip the provided rawSequence if it is gzipped or bzip2 compressed ...
  input:
    getzipfile
  output:
    "RawData/{unzipIntFile}"
  run:
    if (re.search("\.gz$", RawFastq)):
      shell("gunzip -c {input} > {output}")
    elif (re.search("\.bz2$", RawFastq)):
      shell("bunzip2 --keep -d {input}")
  
rule CreateExonBED: ## create a BED version of the GTF file
  input:
    gff = "ReferenceData/"+UnpackedGenomeGFF
  output:
    bed = "ReferenceData/"+UnpackedGenomeGFF+"_exons.bed"
  shell:"""
    scripts/gtf2bed.sh {input.gff} {output.bed}
    """

rule Pychopper:
  input:
    "RawData/"+UnpackedRawFastq
  output:
    pdf = "Analysis/Pychopper/Pychopper_report.pdf",
    fastq = "Analysis/Pychopper/"+UnpackedRawFastq+".pychop.fastq",
    stats = "Analysis/Pychopper/"+UnpackedRawFastq+".pychop.stats",
    scores = "Analysis/Pychopper/"+UnpackedRawFastq+".pychop.scores",
    unclass = "Analysis/Pychopper/"+UnpackedRawFastq+".unclassified.fastq",
  params:
    barcodes_fasta = config["barcodes_fasta"],
    score_percentile = config["score_percentile"]
  run:
    shell("cdna_classifier.py -b {params.barcodes_fasta} -s {params.score_percentile} -x -r {output.pdf} -S {output.stats} -A {output.scores} -u {output.unclass} {input} {output.fastq}")


rule Minimap2: ## map reads using minimap2
    input:
       index = rules.Minimap2Index.output.index,
       fastq = rules.Pychopper.output.fastq if (config["pychopper"]==True) else "RawData/"+UnpackedRawFastq
    output:
       bam = "Analysis/Minimap2/"+UnpackedRawFastq+".bam"
    params:
        opts = config["minimap2_opts"],
        min_mq = config["minimum_mapping_quality"],
    threads: config["threads"]
    shell:"""
    minimap2 -t {threads} -ax splice {params.opts} {input.index} {input.fastq}\
    | samtools view -q {params.min_mq} -F 2304 -Sb | samtools sort -@ {threads} - -o {output.bam};
    samtools index {output.bam}
    """

rule PinfishRawBAM2GFF: ## convert BAM to GFF
    input:
        bam = rules.Minimap2.output.bam
    output:
        raw_gff = "Analysis/Pinfish/raw_transcripts.gff"
    params:
        opts = config["spliced_bam2gff_opts"]
    threads: config["threads"]
    shell:
        "spliced_bam2gff {params.opts} -t {threads} -M {input.bam} > {output.raw_gff}"


rule PinfishClusterGFF: ## cluster transcripts in GFF
    input:
        raw_gff = rules.PinfishRawBAM2GFF.output.raw_gff
    output:
        cls_gff = "Analysis/Pinfish/clustered_transcripts.gff",
        cls_tab = "Analysis/Pinfish/cluster_memberships.tsv",
    params:
        c = config["minimum_cluster_size"],
        d = config["exon_boundary_tolerance"],
        e = config["terminal_exon_boundary_tolerance"],
        min_iso_frac = config["minimum_isoform_percent"],
    threads: config["threads"]
    shell:
        "cluster_gff -p {params.min_iso_frac} -t {threads} -c {params.c} -d {params.d} -e {params.e} -a {output.cls_tab} {input.raw_gff} > {output.cls_gff}"


rule PinfishCollapseRawPartials: ## collapse clustered read artifacts
    input:
        cls_gff = rules.PinfishClusterGFF.output.cls_gff
    output:
        cls_gff_col = "Analysis/Pinfish/clustered_transcripts_collapsed.gff"
    params:
        d = config["collapse_internal_tol"],
        e = config["collapse_three_tol"],
        f = config["collapse_five_tol"],
    shell:
       "collapse_partials -d {params.d} -e {params.e} -f {params.f} {input.cls_gff} > {output.cls_gff_col}"


rule PinfishPolishClusters: ## polish read clusters
    input:
        cls_gff = rules.PinfishClusterGFF.output.cls_gff,
        cls_tab = rules.PinfishClusterGFF.output.cls_tab,
        bam = rules.Minimap2.output.bam
    output:
        pol_trs = "Analysis/Pinfish/polished_transcripts.fas"
    params:
        c = config["minimum_cluster_size"]
    threads: config["threads"]
    shell:
        "polish_clusters -t {threads} -a {input.cls_tab} -c {params.c} -o {output.pol_trs} {input.bam}"


rule MinimapPolishedClusters: ## map polished transcripts to genome
    input:
       index = rules.Minimap2Index.output.index,
       fasta = rules.PinfishPolishClusters.output.pol_trs,
    output:
       pol_bam = "Analysis/Minimap2/polished_reads_aln_sorted.bam"
    params:
        extra = config["minimap2_opts_polished"]
    threads: config["threads"]
    shell:"""
    minimap2 -t {threads} {params.extra} -ax splice {input.index} {input.fasta}\
    | samtools view -Sb -F 2304 | samtools sort -@ {threads} - -o {output.pol_bam};
    samtools index {output.pol_bam}
    """


rule PinfishPolishedBAM2GFF: ## convert BAM of polished transcripts to GFF
    input:
        bam = rules.MinimapPolishedClusters.output.pol_bam
    output:
        pol_gff = "Analysis/Pinfish/polished_transcripts.gff"
    params:
        extra = config["spliced_bam2gff_opts_pol"]
    threads: config["threads"]
    shell:
        "spliced_bam2gff {params.extra} -t {threads} -M {input.bam} > {output.pol_gff}"


rule PinfishCollapsePolishedPartials: ## collapse polished read artifacts
    input:
        pol_gff = rules.PinfishPolishedBAM2GFF.output.pol_gff
    output:
        pol_gff_col = "Analysis/Pinfish/polished_transcripts_collapsed.gff"
    params:
        d = config["collapse_internal_tol"],
        e = config["collapse_three_tol"],
        f = config["collapse_five_tol"],
    shell:
        "collapse_partials -d {params.d} -e {params.e} -f {params.f} {input.pol_gff} > {output.pol_gff_col}"


rule PrepareCorrectedTranscriptomeFasta: ## Generate corrected transcriptome.
    input:
        genome = "ReferenceData/"+UnpackedReferenceFasta,
        gff = rules.PinfishCollapsePolishedPartials.output.pol_gff_col,
    output:
        fasta = "Analysis/Pinfish/corrected_transcriptome_polished_collapsed.fas"
    shell:
        "gffread -g {input.genome} -w {output.fasta} {input.gff}"


rule GffCompare:
    input:
        reference = "ReferenceData/"+UnpackedGenomeGFF,
        exptgff = rules.PinfishCollapsePolishedPartials.output.pol_gff_col
    output:
        "Analysis/GffCompare/nanopore.combined.gtf",
        "Analysis/GffCompare/nanopore.loci",
        "Analysis/GffCompare/nanopore.redundant.gtf",
        "Analysis/GffCompare/nanopore.stats",
        "Analysis/GffCompare/nanopore.tracking"
    shell:
        "gffcompare -r {input.reference} -R -M -C -K -o Analysis/GffCompare/nanopore {input.exptgff}"


rule plotPinfishStats: ## plot_gffcmp_stats.py script from https://github.com/nanoporetech/wub
    input:
        stats = "Analysis/GffCompare/nanopore.stats"
    output:
        pdf = "Analysis/Pinfish/plot_gffcmp_stats.pdf",
        png = "Analysis/Pinfish/plot_gffcmp_stats.png",
        pik = "Analysis/Pinfish/plot_gffcmp_stats.pk"
    shell:
        "plot_gffcmp_stats.py -r {output.pdf} -p ${output.pik} {input.stats} && \
        convert -density 300 -quality 100 {output.pdf}[0] {output.png}"


rule MosDepth: ## Add coverage info for list of expressed gene and plotting in R
    input:
        bam = "Analysis/Minimap2/"+UnpackedRawFastq+".bam",
        bed = "ReferenceData/"+UnpackedGenomeGFF+"_exons.bed"
    output:
        expand("Analysis/MosDepth/{mos_out}", mos_out=mos_out)
    params:
        pfx = "Analysis/MosDepth/gt0"
    threads: config["threads"]
    shell:
        "mosdepth -t {threads} -b {input.bed} {params.pfx} {input.bam}"

rule PrintGraph: ## pring graphs documenting the current pipeline
    output:
        dag = "Static/Images/dag.png",
        graph = "Static/Images/graph.png"
    shell:
        """
        snakemake --forceall --rulegraph | dot -Tpng > {output.graph};
        snakemake --forceall --dag | dot -Tpng > {output.dag}
        """

rule KnitReport: ## Knit the Rmd report from the obtained data
    output:
        report = "Nanopore_Pinfish_Analysis.html"
    shell:
        """
        Rscript --slave -e \'rmarkdown::render(\"Nanopore_Pinfish_Analysis.Rmd\", \"html_document\")\'
        """
