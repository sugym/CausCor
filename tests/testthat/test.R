# Test
## Prepare tables
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

## Save
# excel(list_n, "list_n.xlsx")
# excel(list_40, "list_40.xlsx")
# plot_16(microbiome_table, metabolome_table, list_n, "list_n.pdf")
# plot_16(microbiome_table, metabolome_table, list_40, "list_40.pdf")
