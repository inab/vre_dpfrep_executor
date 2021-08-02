get_gene_sets <- function(prof_mtx, reference, limit) {
  idx <- rownames(prof_mtx) %in% rownames(reference)
  prof_mtx <- prof_mtx[idx,]

  signature <- vector(mode = 'list', length = ncol(prof_mtx))
  names(signature) <- colnames(prof_mtx)

  for (i in colnames(prof_mtx)) {
    signature[[i]] <- vector(mode = 'list', length = 2)
    names(signature[[i]]) <- c('up_genes', 'down_genes')

    expr_val <- prof_mtx[!is.na(prof_mtx[, i]), i]
    sorted_genes <- names(sort(expr_val, decreasing = T))

    signature[[i]]$up_genes <- sorted_genes[1:limit]
    signature[[i]]$down_genes <- rev(sorted_genes)[1:limit]
  }

  signature <- unlist(signature, recursive = F)
  return(signature)
}


calcGseaStatCol <- function(gene_sets, single_gene_list) {
  res <- vector(mode = 'numeric', length = length(gene_sets))
  for (i in seq_along(gene_sets)) {
    idx <- fmatch(gene_sets[[i]], names(single_gene_list))
    res[i] <-
      calcGseaStat(stats = single_gene_list,
                   selectedStats = idx,
                   gseaParam = 0)
  }
  return(res)
}


compute_gsea_fast <- function(gene_sets, multiple_gene_lists) {
  res <-
    matrix(
      0,
      nrow = length(gene_sets),
      ncol = ncol(multiple_gene_lists),
      dimnames = list(names(gene_sets), colnames(multiple_gene_lists))
    )
  for (i in colnames(multiple_gene_lists)) {
    sorted_list <- sort(multiple_gene_lists[, i], decreasing = T)
    res[, i] <- calcGseaStatCol(gene_sets, sorted_list)
  }
  return(res)
}


get_single_strat_pval <-
  function(stat,
           stat_rand,
           direction = 'down',
           reverse = FALSE) {

    stat_rand <- stat_rand[grepl(paste0(direction, '_genes'), rownames(stat_rand)),]
    rownames(stat_rand) <-
      gsub(paste0('.', direction, '_genes'),
           '', rownames(stat_rand))

    stat <- stat[grepl(paste0(direction, '_genes'), rownames(stat)),]
    rownames(stat) <- gsub(paste0('.', direction, '_genes'), '', rownames(stat))

    if (reverse) {
      stat_rand <- t(stat_rand)
      stat <- t(stat)
    }

    p_emp <- stat
    for (i in seq_along(colnames(stat))) {
      for (j in seq_along(stat[, i])) {
        if (direction == 'down')
          p_emp[j, i] <-
            (sum(stat_rand[, i] > stat[j, i]) + 1) / length(stat_rand[, i])
        else
          p_emp[j, i] <-
            (sum(stat_rand[, i] < stat[j, i]) + 1) / length(stat_rand[, i])
      }
    }

    p_emp <- melt(p_emp)
    p_emp <- p_emp[order(p_emp$value),]
    p_emp[, 1:2] <- lapply(p_emp[, 1:2], as.character)
    return(p_emp)
  }


get_all_strat_pval <- function(exp_mtx, rand_mtx, model) {
  ### Get signatures of up and down-regulated genes from random expression profiles

  gene_sets <- get_gene_sets(rand_mtx, model, limit = 250)
  mrk_sets <- get_gene_sets(model, rand_mtx, limit = 250)

  ### Get Enrichment Scores (ES)

  gsea_rand2drug <- compute_gsea_fast(gene_sets, model)
  gsea_drug2rand <- compute_gsea_fast(mrk_sets, rand_mtx)

  ### Get signatures of up and down-regulated genes from expression profiles of CCLs

  gene_sets <- get_gene_sets(exp_mtx, model, limit = 250)
  mrk_sets <- get_gene_sets(model, exp_mtx, limit = 250)

  ### Get Enrichment Scores (ES)

  gsea_data2drug <- compute_gsea_fast(gene_sets, model)
  gsea_drug2data <- compute_gsea_fast(mrk_sets, exp_mtx)

  ###

  a <- get_single_strat_pval(gsea_data2drug, gsea_rand2drug, direction = 'up')
  b <- get_single_strat_pval(gsea_data2drug, gsea_rand2drug)
  c <- get_single_strat_pval(gsea_drug2data, gsea_drug2rand, reverse = T)
  d <- get_single_strat_pval(gsea_drug2data,
                             gsea_drug2rand,
                             direction = 'up',
                             reverse = T)

  ###

  all_strat_pval <- list(a = a,
                         b = b,
                         c = c,
                         d = d)

  for (i in letters[1:4])
    names(all_strat_pval[[i]])[3] <-
      paste(names(all_strat_pval[[i]])[3], i, sep = '_')

  return(all_strat_pval)
}


geo.mean <- function(x, na.rm = TRUE) {
  return(exp(mean(log(x), na.rm = TRUE)))
}


get_drug_efficacy <- function(all_strat_pval) {
  df <-
    Reduce(function(x, y)
             merge(x, y, by = c('Var1', 'Var2')), all_strat_pval)
  df <- data.frame(df[, 1:2], G = apply(df[, 3:6], 1, geo.mean))
  colnames(df) <- c('sample.id', 'drug.id', 'G-value')
  return(df)
}