# CausCor

"CausCor" is an R package for correlation analysis to estimate causality. Particularly, it is useful for detecting the metabolites that would be altered by the gut bacteria.

## Installation

``` r
# In RStudio
devtools::install_github("sugym/CausCor")
```

## Packages used

- cowplot 1.1.1
- dplyr 1.0.8
- ggplot2 3.3.5
- grDevices 4.1.3
- magrittr 2.0.3
- stats 4.1.3
- WriteXLS 6.4.0

## Features


This package has following functions.
- 2 type filtering functions to get correlation lists: `filter_n()`, `filter_40()`
    - All correlation coefficients and R2 scores are calculated by **Overlap** samples only. Overlap is a pair that both bacteria and metabolite abundance are non-zero.
    - `filter_n()` is the filtering function with thresholds for Spearman correlation coefficient, Overlap, and R2 score.
    - `filter_40()` is the more specialized function for causal estimation. Overlap is fixed between 40% and 60% of the total samples by default. (If necessary, you can change them.) And only extract the pattern that the samples who have the bacteria always have the metabolite in a certain pair.

![](/images/figure1.png)

- Function to save the list as .xlsx: `excel()`
- Function to save the scatter plot showing the correlation of pairs in the list as .pdf: `plot_16()`

## Usage

### Preparation

Prepare two category tables and read them as dataframe. The first column has the names of features, and second and subsequent columns have the values for each sample. The order of the samples must be aligned in the two datasets.

![](/images/ex1.png)

### Filtering
- All filtering functions need **microbiome table**, **metabolome table** and **two category names** ("genus" and "metabolome", etc.).

- `filter_n()` requires the setting of thresholds for **Spearman correlation coefficient**, **Overlap**, and **R2 score**.

``` r
# example               
list_n <- filter_n(microbiome_table, metabolome_table, "genus", "metabolome",
                   0.6, # Spearman
                   5, # Overlap
                   0.3) # R2 Score
```

-   `filter_40()` requires the setting of thresholds for **Spearman correlation coefficient** and **R2 score**. If necessary, you can set minimum or maximum Overlap.

``` r
# example
list_40 <- filter_40(microbiome_table, metabolome_table, "genus", "metabolome",
                     0.6, # Spearman
                     0.3) # R2 Score
                        
list_5to10 <- filter_40(microbiome_table, metabolome_table, "genus", "metabolome",
                        0.6, # Spearman
                        0.3, # R2 Score
                        min_sample = 5, # minimum Overlap
                        max_sample = 10) # maximum Overlap
```

### Saving

- Save the list by `excel()`.

``` r
# example
excel(list_n, "list_n.xlsx")
```

- Save the scatter plot by `plot_16()`.

``` r
# example
plot16(microbiome_table, metabolome_table, list_n, "list_n.pdf")
```
