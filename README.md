[![Build Status](https://travis-ci.org/UofABioinformaticsHub/ngsReports.svg)](https://travis-ci.org/UofABioinformaticsHub/ngsReports)

# ngsReports

An R Package for managing FastQC reports and other NGS related log files inside R.
This branch is compatible with Bioconductor >= 3.7 only. To install this package using Bioconductor <= 3.6 (R <= 3.4.4) please use the drop down menu above to change to the branch Bioc3.6, and follow the instructions there.

## Installation
To install required packages follows the instructions below.
Currently you need to install the fastqcTheoreticalGC package separately.

```
source("https://bioconductor.org/biocLite.R")
biocLite(c("BiocGenerics", "BiocStyle", "BSgenome", "checkmate", "devtools", "ggdendro",  "plotly", "reshape2", "Rsamtools", "scales", "shiny", "ShortRead", "tidyverse",  "viridis", "viridisLite", "zoo", "shinyFiles"))
devtools::install_github('mikelove/fastqcTheoreticalGC')
devtools::install_github('UofABioinformaticsHub/ngsReports', build_vignettes = FALSE)
library(ngsReports)
```

# Vignette

The vignette for usage is [here](https://uofabioinformaticshub.github.io/ngsReports/vignettes/ngsReportsIntroduction)

# ShinyApp Usage 

**We recomend opening the shiny app into Google Chrome**

this can be done by clicking `Open in Browser` after executing `fastqcShiny()`

For a analysis of multiple fastqc reports use the shinyApp by running:
`fastqcShiny()`
once inside the shiny app, files can be input by clicking the `Choose Files` button.
This will then open a pop-up window to select your fastqcReports (select multiple files by holding control, etc.) 
once selected files will load and first plot will appear.
