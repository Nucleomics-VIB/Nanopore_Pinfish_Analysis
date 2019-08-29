[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)

Nanopore_Pinfish_Analysis
==========

This Snakemake pipeline and accompanying RStudio report are largely inspired by the ```ont_tutorial_pinfish``` found at [nanoporetech](https://github.com/nanoporetech/ont_tutorial_pinfish) with addition of a few analysis steps.

Please refer to the original document for installilng the necessary components and for more info about the pipeline.

Running this code requires:

* installing all required conda dependencies from the provided **environment.yaml** (*conda env create --name pinfish_3.6--file=environment.yaml*)
* editing the **config.yaml** file tomatch your own machine, reference genome, and data
* adding the required data files in due locations (matching the yaml)
* edit the **Preamble.md** file to include a text describing the 'Aim' of the experiment. This text will be added to the report as first section and is one of the two report sections that can be edited by the end-user.
* optionally edit **Conclusion.md** that will be added at the end of the report during knitting.

* run Snakemake with ```snakemake --use-conda -j <thread number>```

If all goes well, the proper analysis will be followed by the making of the html report using Rmarkdown and conversion to a html report file with pictures and tables.

* the final data files are put in the folder ```Analysis```
* the final report should appear as ```Nanopore_Pinfish_Analysis.html```

<hr>

<h4>Please send comments and feedback to <a href="mailto:nucleomics.bioinformatics@vib.be">nucleomics.bioinformatics@vib.be</a></h4>

<hr>

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
