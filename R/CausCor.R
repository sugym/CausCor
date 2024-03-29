# Correlation analysis to infer causality between A and B

# ==============================================================================
#' @import dplyr
#' @import ggplot2
#' @importFrom cowplot plot_grid
#' @importFrom grDevices dev.off
#' @importFrom grDevices pdf
#' @importFrom magrittr set_colnames
#' @importFrom stats cor
#' @importFrom stats lm
#' @importFrom utils write.csv write.table
#' @importFrom WriteXLS WriteXLS


# Make matrix of A-B
bind_mat <- function(a_mat, b_mat) {
  df <-
    rbind(a_mat[, 2:ncol(a_mat)], b_mat[, 2:ncol(b_mat)]) %>%
    t() %>%
    apply(c(1, 2), as.numeric) %>%
    as.data.frame()
  colnames(df) <- c(a_mat[, 1], b_mat[, 1])
  df[df == 0] <- NA
  return(df)
}

# General filtering function
general <- function(a_mat, b_mat, a_category, b_category,
                    min_cor, min_r2, min_sample, max_sample, type) {
  # Prepare matrix
  mat <- bind_mat(a_mat, b_mat)
  a_num <- nrow(a_mat)
  b_num <- nrow(b_mat)

  mat_1 <- mat %>% as.matrix()
  mat_1[mat_1 > 0] <- 1
  mat_1[is.na(mat_1)] <- 0

  # Overlap list
  o_count <-
    c((t(mat_1) %*% mat_1)[1:a_num, (a_num + 1):(a_num + b_num)])

  # Spearman list
  cal_rs <- function(mat, a_num, b_num) {
    return(cor(mat, use = "pairwise.complete.obs", method = "spearman")[
      1:a_num, (a_num + 1):(a_num + b_num), drop = F])
  }
  cor_s <- cal_rs(mat, a_num, b_num) # Spearman
  a_na <- mat
  b_na <- mat
  a_na[, c((a_num + 1):(a_num + b_num))][
    is.na(a_na[, c((a_num + 1):(a_num + b_num))])] <- 0
  b_na[, c(1:a_num)][is.na(b_na[, c(1:a_num)])] <- 0
  rs_a <- cal_rs(a_na, a_num, b_num) # Spearman of A to B
  rs_b <- cal_rs(b_na, a_num, b_num) # Spearman of B to A

  # Make table
  if (type == 1 || type == 3) {
    table <- cbind(rep(c(rownames(cor_s)), b_num),
                   rep(c(colnames(cor_s)), each = a_num),
                   c(cor_s), c(rs_a), c(rs_b), o_count) %>%
      as.data.frame() %>%
      set_colnames(c(a_category, b_category,
                   "spearman_cor", "rs_a", "rs_b", "overlap"))
    table <- cbind(table[, c(1:2)], apply(table[, c(3:6)], 2, as.numeric))
  }else{
    mat_2 <- mat_1 %>% as.data.frame()
    b_0_count <- c(sapply(1:b_num, function(i) {
      sapply(1:a_num, function(j) {
        tmp <- mat_2[, j] > mat_2[, a_num + i]
        tmp[tmp == TRUE] <- 1
        if (sum(tmp) == 0) {
          0
        }else{
          1
        }
      })
    }))
    table <- cbind(rep(c(rownames(cor_s)), b_num),
                   rep(c(colnames(cor_s)), each = a_num),
                   c(cor_s), c(rs_a), c(rs_b), o_count, b_0_count) %>%
      as.data.frame() %>%
      filter(.data$b_0_count == 0) %>%
      select(-7) %>%
      set_colnames(c(a_category, b_category,
                     "spearman_cor", "rs_a", "rs_b", "overlap"))
    table <- cbind(table[, c(1:2)], apply(table[, c(3:6)], 2, as.numeric))
   }

  # Filtering by Spearman and Overlap
  filter_1 <- table %>%
    arrange(desc(table$spearman_cor)) %>%
    filter(.data$spearman_cor <= -min_cor | min_cor <= .data$spearman_cor)
  if (type == 1) {
    filter_1 <- filter_1 %>% filter(.data$overlap >= min_sample)
  }else{
    filter_1 <- filter_1 %>%
      filter(min_sample <= .data$overlap & .data$overlap <= max_sample)
  }

  # R2 score list
  r2 <- lapply(seq_len(nrow(filter_1)), function(x) { # R2
    summary(lm(mat[filter_1[, 1]][[x]] ~
                 mat[filter_1[, 2]][[x]], mat))$r.squared
  }) %>%
    as.data.frame() %>%
    t()

  r2_a <- lapply(seq_len(nrow(filter_1)), function(x) { # R2 of A to B
    summary(lm(a_na[filter_1[, 1]][[x]] ~
                 a_na[filter_1[, 2]][[x]], a_na))$r.squared
  }) %>%
    as.data.frame() %>%
    t()
  r2_b <- lapply(seq_len(nrow(filter_1)), function(x) { # R2 of B to A
    summary(lm(b_na[filter_1[, 1]][[x]] ~
                 b_na[filter_1[, 2]][[x]], b_na))$r.squared
  }) %>%
    as.data.frame() %>%
    t()
  r2_diff <- r2_a - r2_b

  # Filtering by R2
  filter_2 <-
    cbind(filter_1, r2, r2_a, r2_b, r2_diff) %>% filter(r2 >= min_r2)
  filter_2 <- filter_2 %>% arrange(desc(filter_2$r2_diff))
  rownames(filter_2) <- NULL
  filter_2[, c(3:5, 7:10)] <- filter_2[, c(3:5, 7:10)] %>% signif(digits = 3)

  return(filter_2)
}

# ==============================================================================
#' Make list of A-B pair causal correlations - Normal Filtering version
#' @param a_mat Matrix of measurements of A for each sample.
#' @param b_mat Matrix of measurements of B for each sample.
#' @param a_category Category name of A.
#' @param b_category Category name of B.
#' @param min_cor Minimum spearman correlation coefficient.
#' @param min_r2 Minimum R2 score.
#' @param min_sample Minimum number of samples.
#'
#' @export
#'
filter_n <- function(a_mat, b_mat, a_category, b_category,
                     min_cor, min_r2, min_sample) {
  return(general(a_mat, b_mat, a_category, b_category,
                 min_cor, min_r2, min_sample, NULL, 1))
}
# ==============================================================================
#' Make list of A-B pair causal correlations - 40% Filtering version
#' @param a_mat Matrix of measurements of A for each sample.
#' @param b_mat Matrix of measurements of B for each sample.
#' @param a_category Category name of A.
#' @param b_category Category name of B.
#' @param min_cor Minimum spearman correlation coefficient.
#' @param min_r2 Minimum R2 score.
#' @param min_sample Minimum number of samples. The default is 40% of the
#' total samples.
#' @param max_sample Maximum number of samples. The default is 60% of the
#' total samples.
#'
#' @export
#'
filter_40 <- function(a_mat, b_mat, a_category, b_category, min_cor, min_r2,
                      min_sample = ceiling((ncol(a_mat) - 1) * 0.4),
                      max_sample = ncol(a_mat) - 1 - min_sample) {
  return(general(a_mat, b_mat, a_category, b_category, min_cor, min_r2,
                 min_sample, max_sample, 2))
}

# ==============================================================================
#' Make list of A-B pair causal correlations
#' @param a_mat Matrix of measurements of A for each sample.
#' @param b_mat Matrix of measurements of B for each sample.
#' @param a_category Category name of A.
#' @param b_category Category name of B.
#' @param min_cor Minimum spearman correlation coefficient.
#' @param min_r2 Minimum R2 score.
#' @param min_sample Minimum number of samples.
#' @param max_sample Maximum number of samples. The default is the total
#' number of samples.
#' @param direction Extract only directional associations where a change
#' in category A causes a change in category B. The default is True.
#'
#' @export
#'
filter_cc <- function(a_mat, b_mat, a_category, b_category, min_cor, min_r2,
                      min_sample, max_sample = ncol(a_mat) - 1, direction = T) {
  if (direction == T) {
    type <- 2
  }else{
    type <- 3
  }
  return(general(a_mat, b_mat, a_category, b_category, min_cor, min_r2,
                 min_sample, max_sample, type))
}

# ==============================================================================
#' Save list as a text file
#' @param list List of results.
#' @param out_info Output directory.
#' @param file_type Choose from "excel", "csv", "tsv".
#'
#' @export
#'
save_text <- function(list, out_info, file_type) {
  if (file_type == "excel") {
    WriteXLS(list, ExcelFileName = out_info)
  }else if (file_type == "csv") {
    write.csv(list, out_info, quote = F, row.names = F)
  }else if (file_type == "tsv") {
    write.table(list, out_info, quote = F, sep = "\t", row.names = F)
  }
}

# ==============================================================================
#' Save scatter plots
#' @param a_mat Matrix of measurements of A for each sample.
#' @param b_mat Matrix of measurements of B for each sample.
#' @param list List of results.
#' @param out_info Output directory.
#' @param x_italic Italicize the x-axis label of the plot. The default is False.
#' @param y_italic Italicize the y-axis label of the plot. The default is True.
#'
#' @export
#'
plot_16 <- function(a_mat, b_mat, list, out_info, x_italic = F, y_italic = T) {
  # Prepare matrix
  mat <- bind_mat(a_mat, b_mat)

  # Set one scatter plot
  plot_1 <- function(mat, list, num) {
    mat_1 <- mat
    mat_1[is.na(mat_1)] <- 0
    a <- mat_1[[list[num, 2]]]
    b <- mat_1[[list[num, 1]]]
    c <- a * b
    mat_2 <- cbind(a, b, c) %>% as.data.frame()
    mat_2$c[mat_2$c > 0] <- 1

    title <- paste0(
      "rs = ", list[, 3][num], ", n = ", list[, 6][num], ", R2 = ",
      list[, 7][num], "\nrs_a = ", list[, 4][num], ", rs_b = ",
      list[, 5][num], "\nR2_a = ", list[, 8][num], ", R2_b = ",
      list[, 9][num], ", R2_diff = ", list[, 10][num])

    if (nchar(list[, 1][num]) < 35) {
      y <- list[, 1][num]
    }else{
      y <- sub("_", "_\n", list[, 1][num])
    }
    if (nchar(list[, 2][num]) < 40) {
      xsize <- 5
    }else{
      xsize <- 4
    }
    if (x_italic == F) {
      x_italic <- NULL
    }else{
      x_italic <- "italic"
    }
    if (y_italic == T) {
      y_italic <- "italic"
    }else{
      y_italic <- NULL
    }
    mat_2 %>%
      ggplot(aes(x = a, y = b)) +
      geom_point(size = 0.3, aes(colour = factor(c))) +
      theme_classic() +
      labs(x = list[, 2][num], y = y, title = title, tag = num) +
      theme(plot.title = element_text(size = 4, hjust = 0.5, vjust = -1),
            plot.margin = unit(c(0.3, 0.3, 0.3, 0.3), "lines"),
            plot.tag = element_text(size = 5, hjust = 1, vjust = -1),
            axis.text = element_text(size = 3, colour = "black"),
            axis.text.x = element_text(vjust = 1),
            axis.text.y = element_text(hjust = 1),
            axis.title.x =
              element_text(size = xsize, vjust = 1, face = x_italic),
            axis.title.y = element_text(size = 5, vjust = 1, face = y_italic),
            axis.line = element_line(size = 0.3, lineend = "square"),
            axis.ticks = element_line(size = 0.3, colour = "black"),
            axis.ticks.length = unit(0.7, "mm"),
            legend.position = "none",
            aspect.ratio = 1) +
      scale_colour_manual(values = c("0" = "orange", "1" = "royalblue")) %>%
      return()
  }

  # 16 figures per page
  pdf(out_info)
  if (nrow(list) <= 16) {
    plot_grid(plotlist = lapply(seq_len(nrow(list)), function(x) {
      plot_1(mat, list, x)
    }), nrow = 4, ncol = 4) %>% print()
  }else{
    lapply(1:(nrow(list) %/% 16), function(x) {
      i <- (x - 1) * 16 + 1
      plot_grid(plotlist = lapply(c(i:(i + 15)), function(x) {
        plot_1(mat, list, x)
      }), nrow = 4, ncol = 4) %>% print()
    })
    if (nrow(list) %% 16 != 0) { # Last page if not divisible by 16
      plot_grid(plotlist = lapply(c((nrow(list) %/% 16 * 16 + 1):nrow(list)),
                                  function(x) {
                                    plot_1(mat, list, x)
                                  }), nrow = 4, ncol = 4) %>% print()
    }
  }
  dev.off()
}
