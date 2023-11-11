# CausCor

"CausCor" is an R package for correlation analysis to estimate causality. Particularly, it is useful for detecting the metabolites that would be altered by the gut bacteria.

## Installation
CausCor can be installed from CRAN, 
``` r
# From CRAN
install.packages("CausCor")
```
or from GitHub,
``` r
# From GitHub
devtools::install_github("sugym/CausCor")
```

## Packages used

- cowplot 1.1.1
- dplyr 1.0.8
- ggplot2 3.3.5
- grDevices 4.1.3
- magrittr 2.0.3
- stats 4.1.3
- utils 4.1.3
- WriteXLS 6.4.0

## Features


This package has following functions.
- 3 type filtering functions to get correlation lists: `filter_n`, `filter_40`, `filter_cc`
    - All correlation coefficients and R2 scores are calculated by **Overlap** samples only. Overlap is a pair that both bacteria and metabolite abundance are non-zero.
    - `filter_n` is the filtering function with thresholds for Spearman correlation coefficient, Overlap, and R2 score.
    - `filter_40` is the more specialized function for causal estimation. Overlap is fixed between 40% and 60% of the total samples by default. (If necessary, you can change them.) And only extract the pattern that the samples who have the bacteria always have the metabolite in a certain pair.
    - `filter_cc` is a function that integrates `filter_n` and `filter_40`. You are free to select the threshold to use and whether or not to use directional filtering. We recommend using this function rather than the two above.

![](/images/figure1.png)

- Function to save the list as a text file: `save_text`
- Function to save the scatter plot showing the correlation of pairs in the list as a pdf file: `plot_16`

## Usage

### Preparation

Prepare two category tables and read them as dataframe. The first column has the names of features, and second and subsequent columns have the values for each sample. The order of the samples must be aligned in the two datasets.

![](/images/ex1.png)

### Filtering
- All filtering functions need **microbiome table**, **metabolome table** and **two category names** ("genus" and "metabolome", etc.).

- `filter_n` requires the setting of thresholds for **Spearman correlation coefficient**, **Overlap**, and **R2 score**.

``` r
# Example               
list_n <- filter_n(microbiome_table, metabolome_table, "genus", "metabolome",
                   0.6, # Spearman
                   5, # Overlap
                   0.3) # R2 Score
```

-   `filter_40` requires the setting of thresholds for **Spearman correlation coefficient** and **R2 score**. If necessary, you can set minimum or maximum Overlap.

``` r
# Example
list_40 <- filter_40(microbiome_table, metabolome_table, "genus", "metabolome",
                     0.6, # Spearman
                     0.3) # R2 Score
                        
list_5to10 <- filter_40(microbiome_table, metabolome_table, "genus", "metabolome",
                        0.6, # Spearman
                        0.3, # R2 Score
                        min_sample = 5, # minimum Overlap
                        max_sample = 10) # maximum Overlap
```

-   `filter_cc` requires the setting of minimum value of **Spearman correlation coefficient** and **R2 score**, minimum and maximum value of **Overlap**. You can select to extract only the association that a sample with a value in the x-axis category (bacteria) will always have a value in the y-axis category (metabolite). This feature is True by default.

``` r
# Example
list_cc <- filter_cc(microbiome_table, metabolome_table, "genus", "metabolome",
                     min_cor = 0.6, # Spearman
                     min_r2 = 0.3, # R2 Score
                     min_sample = 5, # minimum Overlap
                     max_sample = 10, # maximum Overlap
                     direction = True) # select direction filtering
```

### Saving

- Save the list by `save_text`.

``` r
# Example
# You can choose file type from "excel", "csv", "tsv"
save_text(list_n, "list_n.xlsx", "excel")
```

- Save the scatter plot by `plot_16`. You can select to italicize the axis labels. Only the x-axis is italicized by default.

``` r
# Example
plot16(microbiome_table, metabolome_table, list_n, "list_n.pdf")
```
