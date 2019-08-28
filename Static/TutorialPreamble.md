# Tutorial objectives

The **pinfish tutorial** is intended as a functional guide to demonstrate how the Oxford Nanopore Technologies **`pinfish`** software may be used to annotate genes and their isoforms by using long sequence read cDNA data and a reference genome. The workflow described compares the gene isoforms identified by **`pinfish`** with known gene annotations. This enables the discovery of novel gene isoforms.

The tutorial is provided with example data and the tutorial workflow is used to address experimental questions that include 

* What are the read characteristics for my starting sequence collection?
* Which fraction of my sequence reads appear full length?
* How many genes and transcripts are identified?
* How do the identified transcripts correspond to the reference genome annotation?
* Which pinfish annotations are from novel genes or gene isoforms?
* How can I visually explore a specific gene isoform?

Editing of the workflow's configuration file, **`config.yaml`** will allow the workflow to be run with different starting cDNA sequence collections, reference genomes and gene annotations.

## Software tools used by the tutorial include 

* **`R`** for statistical analysis and reporting
* **`conda`** for management of bioinformatics software installations
* **`snakemake`** for managing the bioinformatics workflow
* **`pychopper`** for the filtering of candidate full-length transcript sequences
* **`minimap2`** for mapping sequence reads to reference genome
* **`samtools`** for SAM/BAM handling and mapping statistics
* **`pinfish`** for the clustering, polishing, and reduction of spliced sequence reads
* **`racon`** is used by **`pinfish`** for the polishing of isoform consensus sequences
* **`GffCompare`** for comparing gene annotations for novel isoform discovery
* **`IGV`** for the visualisation of mapped reads and gene isoforms

## The computational requirements include 

* A computer running Linux (Centos7, Ubuntu 18_10, Fedora 29) 
* At least 6 Gb RAM (when using the Drosophila example data) 
* At least 2 Gb free disk space for analysis and indices
* Runtime with provided example data - approximately 30 minutes


\pagebreak

# Software installation

1. The tutorial's software requirements are managed by the **`conda`** package manager. Please install **`conda`** as described at [https://conda.io/docs/install/quick.html](https://conda.io/docs/install/quick.html). You will need to accept the license agreement during installation, and we recommend that you allow the conda installer to prepend its path to your `.bashrc` file when asked.
```
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh
    bash
```
2. Download the **`pinfish tutorial`** & example files into a folder named `Pinfish`. This tutorial requires the **`git-lfs`** large file support capabilities which should be installed through **`conda`** first.
```
    conda install -c conda-forge git-lfs
    git lfs install
    git clone https://github.com/nanoporetech/ont_tutorial_pinfish.git Pinfish
```
3. Change your working directory into the new `Pinfish` folder
```
    cd Pinfish
```
4. Install the tutorial's software dependencies using the **`conda`** package manager
```
    conda env create --name Pinfish --file environment.yaml
```
5. Initialise the tutorial's conda software environment with 
```
    source activate Pinfish
```


\pagebreak




# Introduction

cDNA and direct-RNA sequencing enable the preparation of full-length sequence transcripts from purified mRNA samples. Collections of cDNA sequences may be used for either differential gene expression analyses or for the characterisation and annotation of genes and their isoforms. In this tutorial we will look at a workflow that uses full-length cDNA sequence reads to discover genes and annotate their isoforms.

[Oxford Nanopore Technologies](https://nanoporetech.com) provides a number of [sequencing solutions](https://nanoporetech.com/rna) to allow users to generate a "snapshot" of gene expression. This can be achieved by both sequencing the mRNA [directly](https://store.nanoporetech.com/catalog/product/view/id/167/s/direct-rna-sequencing-kit/category/28/), or via a complementary DNA ([cDNA](https://store.nanoporetech.com/catalog/product/view/id/177/s/cdna-pcr/category/28/)) proxy. In contrast to short read sequencing technologies, entire mRNA transcripts can be captured as single reads. 

The Oxford Nanopore Technologies protocols for preparing sequencing libraries from cDNA utilise oligonucleotide adapters. Different adapters are ligated to the 5' and 3' end of the cDNA molecule. The presence of both adapter sequences can be used to flag a probable full-length cDNA sequence and can be used to orientate the cDNA molecules relative to the native mRNA. These aspects of the library preparation are exploited by the [**`pychopper`**](https://github.com/nanoporetech/pychopper) software to identify likely full-length sequences.

These full-length transcript sequences can be mapped to a reference genome using a spliced alignment strategy. A transcribed cDNA sequence will map to a gene's exons. Genes can be found by filtering the mapping alignments for genomic regions with sufficient sequence depth-of-coverage. The differences in mapping coordinates at a single gene locus can be used to identify different gene isoforms. [**`Pinfish`**](https://github.com/nanoporetech/pinfish) implements such an approach to transcript discovery. 

This tutorial demonstrates a workflow for the *de novo* annotation and characterisation of genes and their isoforms from cDNA sequence libraries. This utilises the **`pychopper`** and **`pinfish`** software. Additional steps are included using the **`IGV`** genome browser to visualise the gene annotations and the **`GffCompare`** software is used to select for known and potentially novel transcripts.

A pre-prepared dataset is distributed with the tutorial. The fastq format data is from a PCR-based cDNA sequencing experiment. Using the Oxford Nanopore Technologies PCR cDNA kit (PCS-109), 1 ng of poly A+ *Drosophila melanogaster* mRNA ([*Drosophila melanogaster*, Adult Poly A+ RNA, Clontech](https://www.takarabio.com/products/cdna-synthesis/purified-total-rna-and-mrna/poly-a-rna-miscellaneous-species)) was reverse transcribed according to the PCS-109 protocol. cDNA molecules were amplified using 14 cycles of PCR and sequenced on a FLO-MIN106D flowcell for 24 hours. The base-called and QC passing sequence reads were mapped to the Drosophila genome (Drosophila_melanogaster.BDGP6 release 95) using *minimap 2*. Reads mapping to chromosome 4 were selected and the largest clusters identified by the **`Pinfish`** analysis were downsampled to *500* members. This example dataset is a synthetic reduced dataset that will map mainly to chromosome 4. This dataset is sufficient for a demonstration of this workflow in a reasonable time on a standard computer.

The goals included for this tutorial include:

* To introduce a literate framework for analysing Oxford Nanopore cDNA data prepared using MinION, GridION or PromethION flowcells
* To utilise best data-management practices
* To provide basic cDNA sequence QC metrics enabling the review and consideration of the starting experimental data
* To use the **`pychopper`** software to select full-length transcripts
* To use the **`pinfish`** software to annotate genes and their isoforms
* To visualise genes and their isoforms using **`IGV`**
* To use the **`GffCompare`** software to select for known and novel isoforms from the gene annotation


# Getting started and best practices

This tutorial requires a computer workstation running a Linux operating system. The workflow described has been tested using **`Fedora 29`**, **`Centos 7`**, and **`Ubuntu 18_10`**. This tutorial has been prepared using the **`Rmarkdown`** file format. This utilises *markdown* and the document also contains chunks of embedded **`R code`** that are dynamically executed during the report preparation - see @R-rmarkdown for more information.

The described analytical workflow makes extensive use of the **`conda`** package management and the **`snakemake`** workflow software. These software packages and the functionality of **`Rmarkdown`** provide the source for a rich, reproducible and extensible tutorial document.

As a best practice this tutorial will separate primary cDNA sequence data (the base-called fastq files) from the **`Rmarkdown`** source, and the genome reference data. The analysis results and figures will also be placed in a separate working folders. The required layout for the primary and reference data is shown in the figure below. This minimal structure will be prepared over the next sections of this tutorial. The cDNA sequences to be analysed must be placed within the folder called **`RawData`**, the reference genome and annotation files must be placed in the folder named **`ReferenceData`**.

![](Static/Images/FolderLayout.png) 

The figure above shows an example of the folder layout after the tutorial has been cloned from `github` and reference genome data has been downloaded. 

* `config.yaml` defines the tutorial configuration - this includes sequence files, reference genomes and parameters to be used
* `environment.yaml` defines the software to be downloaded and installed by the **`conda``** software manager
* `Nanopore_Pinfish_Tutorial.Rmd` is the **`Rmarkdown template`** that will be used to prepare the analysis report
* `RawData` is a folder and your sequence files should be placed in this folder
* `ReferenceData` is a folder that should contains reference genome information
* `Snakefile` is a file that describes the workflow to be run using the **`snakemake`** command
* `Static` is a folder containing various accessory files; these includes figures used within the tutorial, citations and text


# Experimental setup

![](Static/Images/ConfigYamlParameters.png) 

The experimental design for the tutorial is described in the file called **`config.yaml`** - the example provided with the tutorial is shown in the figure above.

* **`genome_fasta`** defines the reference genome sequence which sequence reads will be mapped to. This can either be a URL to a fasta format sequence file at e.g. ENSEMBL/NCBI or can be the name of a file already in the `ReferenceData` folder
* **`genome_annot`** defines the GFF format gene annotations for the genome sequence described by `genome_fasta`. This can be either a URL or a file name for a file already placed in the `ReferenceData` folder
* **`raw_fastq`** defines the input sequences for the Pinfish workflow. This should be a fastq format sequence file, placed in the `RawData` folder
* **`minimum_cluster_size`** defines the minimum number of sequence reads that must map within a sequence cluster for it to be considered for annotation
* **`minimum_mapping_quality`** defines a minimum mapping quality threshold for the consideration of mapped sequence reads

Other parameters that can modified include parameters for controlling read mapping to the reference genome, expectations for intron and exon boundaries and rules for collapsing annotations. 



# Snakemake

**`Snakemake`** (@snakemake2012) is a workflow management system.


![](Static/Images/dag.png) 


The workflow shown in the figure above describes the **`Snakemake`** workflow contained in this tutorial. The core tasks involved with mapping sequence reads and the preparation of transcript clusters and their annotations are copied from the [**`pipeline-pinfish-analysis`**](https://github.com/nanoporetech/pipeline-pinfish-analysis) workflow.

The **`Snakemake`** workflow imports configuration parameters from the **`config.yaml`** file described in the previous section. The `Snakefile` describes the analytical workflow and the locations of the required input and output files. To modify and adapt the workflow, it is recommended to first modify the `config.yaml` file.

The **`Snakemake`** tasks can be summarised as

1. Download the `fasta` format reference genome sequence to which sequence reads will be mapped
2. Download the `GFF` format reference genome annotations to be used for the analysis
4. Use the **`pychopper`** software to select for likely full-length cDNA transcript sequences and orientate them so that the protein coding sequence is present on the forward cDNA strand
5. Create a genome index for read mapping using the **`minimap2`** (@minimap22018) software
6. Map the `pychopper`-filtered sequence reads against the reference genome using `minimap2`; sort and index the mapping results with **`samtools`** (@samtools2009)
7. Prepare a GFF annotation from the mapped read BAM file using **`Pinfish`** `spliced_bam2gff`
8. Correct sequence consensus (using **`Racon`** @racon2017) for transcript clusters with the **`pinfish`** `polish_clusters` tool
9. Remap the polished and transcript clustered sequence reads against the reference genome using `minimap2` 
10. Prepare a GFF annotation from the polished and clustered mapped transcript BAM file using **`pinfish`** `spliced_bam2gff`
11. Collapse redundant and partial transcript annotations using **`pinfish`** `collapse_partials`  
12. Prepare a fasta file of non-redundant, polished and collapsed transcripts using [**`gffread`**](https://github.com/gpertea/gffread)
13. Compare the de novo produced transcript annotations with the reference genome annotations using [**`GFFcompare`**](https://ccb.jhu.edu/software/stringtie/gffcompare.shtml). This is used to identify novel gene isoforms


To run the **`snakemake`**  workflow

```
# type snakemake to run the workflow
# don't include <NPROC> but rather the number of processor cores available (e.g. 2 or 4)

snakemake -j <NPROC>
```

The **`-j <nprocs>`** flag instructs the **`snakemake`** process to use a specific number of threads. This value should be adjusted to best correspond to your computer system.



## Prepare the tutorial report


The analysis of the sequences specified within the  **`config.yaml`** file and rendered through the **`Rmarkdown`** file will be performed as part of the **`knit`** process. This will load the results from the **`snakemake`** process, will prepare a sequence analysis, render figures and prepare the report. The command below will `knit` the document to produce the html format report. 

```
R --slave -e 'rmarkdown::render("Nanopore_Pinfish_Tutorial.Rmd", "html_document")'
```

\pagebreak
