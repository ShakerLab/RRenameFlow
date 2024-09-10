## R-Rename FCS

This short R script takes an input folder of FCS files and configurably does the following:
- Unflips width and height axes to account for BD FACSDiva's improper flipping of these parameters when exporting an entire experiment
- Renames a map of parameters so they can be reflected of the actual fluorophore names and appropriately updates the compensation matrix
- Renames the FCS $FIL keyword to the given file's name

### Prerequisites

Install R and the flowCore package:

#### R

Install R via Winget:

```ps1
winget install -e --id RProject.R
```

Then install the flowCore package. Run:

```ps1
R.exe
```

#### FlowCore

This will obtain an R prompt. Then:

```r
install.packages('jsonlite', dependencies=TRUE, repos='http://cran.rstudio.com/')
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("flowCore")
```

### Usage

Create a `config.json` file in the same folder as the script. For example:

```json
{
    "parameter_replacements": {
        "BV421-A": "DAPI-eF450-A",
        "APC-A": "eF660-A"
    },
    "flip_width_height": true
}
```

Then via Powershell in the directory containing `index.r` and the `data` folder for FCS files:

```ps1
Rscript index.r
```
