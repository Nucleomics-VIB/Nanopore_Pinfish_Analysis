

# Customise the tutorial and explore your own data

Final thoughts; behind this **`Rmarkdown`** file is a modest amount of **`R code`** - please explore the **`Rmarkdown`** template; modify it, and run with your own samples.

The **`Nanopore_Pinfish_Tutorial.Rmd`** script contains the R code to perform the data presentation for the **`Pinfish`** analysis. This Rmarkdown script will first import the **`config.yaml`** configuration file to load the appropriate sequence files and references, and to identify where the **`snakemake`** process will have written result files. Please edit the **`config.yaml`** file to point to your own files, delete the **`Analysis`** folder and its contents and re-run the whole **`snakemake`** process. 

The **`config.yaml`** and **`Nanopore_Pinfish_Tutorial.Rmd`** files can both be edited directly in Rstudio. The code below shows the command to open the configuration file with the **`Rstudio`** software.

```
rstudio config.yaml
```



To extract the whole set of **`R code`** from the **`Rmarkdown`**, use the **`purl`** command - this will extract the R code into its own file.

```
knitr::purl("Nanopore_Pinfish_Tutorial.Rmd", quiet=TRUE)
```


\pagebreak



# References and Citations

