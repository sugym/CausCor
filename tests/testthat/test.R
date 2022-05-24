# Test
## Prepare tables
### The following data are processed samples from D. B. Dhakan et al. (2019)
microbiome_table <- read.csv("../input_data/India_LOC1_genus.csv")
metabolome_table <- read.csv("../input_data/India_LOC1_serum_metabolome.csv")

## Filtering functions
list_n <- filter_n(a_mat = microbiome_table, b_mat = metabolome_table,
                           a_category = "genus", b_category = "metabolome",
                           min_cor = 0.3, min_sample = 5, min_r2 = 0.1)
list_40 <- filter_40(a_mat = microbiome_table, b_mat = metabolome_table,
                             a_category = "genus", b_category = "metabolome",
                             min_cor = 0.3, min_r2 = 0.1)
test_that("normal filtering has failed", {
  expect_equal(nrow(list_n), 37)
})
test_that("40% filtering has failed", {
  expect_equal(nrow(list_40), 6)
})
