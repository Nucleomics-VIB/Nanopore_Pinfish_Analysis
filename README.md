[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)

Nanopore_Pinfish_Analysis
==========

This Snakemake pipeline and accompanying RStudio report are largely inspired by the ```ont_tutorial_pinfish``` found at [nanoporetech](https://github.com/nanoporetech/ont_tutorial_pinfish) with addition of a few analysis steps.

Please refer to the original document for installilng the necessary components and for more info about the pipeline.

Running this code requires:

* adding the required data files in due locations (see yaml)
* editing the config.yaml file accordinly
* run Snakemake with 'snakemake --use-conda -j <thread number>

If all goes well, the proper analysis will be followed by the making of the html report in R.

* the final data files are put in the folder Analysis
* the final report should appear as ```Nanopore_Pinfish_Analysis.html```

<hr>

<h4>Please send comments and feedback to <a href="mailto:nucleomics.bioinformatics@vib.be">nucleomics.bioinformatics@vib.be</a></h4>

<hr>

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
