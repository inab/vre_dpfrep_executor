library(fastmatch)
library(fgsea)
library(openxlsx)
library(reshape2)
library(here)

source(here("dpfrep", "dpfrep_functions.R"))

message("STARTING DRUG PREDICTION PROCESS")

message("Reading input arguments")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  print("Please supply all arguments.")
}

input_file <- args[1]
tumor_type <- args[2]
model_name <- args[3]

exp_mtx <- as.matrix(read.csv(file = input_file, check.names = F, row.names = 1, stringsAsFactors = F))

message('Generating randomized expression profiles')

time <- ceiling(10000 / ncol(exp_mtx))
rand_mtx <- do.call(cbind, replicate(time, exp_mtx, simplify = F))

dms <- prod(dim(rand_mtx))
thr <- round(dms * 0.25)

set.seed(123)
idx <- sample(1:dms, thr)
rand_mtx[idx] <- sample(rand_mtx[idx])
colnames(rand_mtx) <- paste('rand', 1:ncol(rand_mtx), sep = '')

message("Importing model(s)")

if (model_name == 'Ensemble') model_name <- c('Broad', 'Sanger')

PCC <- vector(mode = 'list', length = length(model_name))
names(PCC) <- model_name

for (i in model_name) {

  root <- paste(here("dpfrep", "data"), tumor_type, i, sep = '/')
  all_rds <- list.files(root)
  PCC[[i]] <- vector(mode = 'list', length = length(all_rds))
  for (j in seq_along(all_rds)) {
    PCC[[i]][[j]] <- readRDS(paste(root, all_rds[j], sep = '/'))
  }
  PCC[[i]] <- do.call(rbind, PCC[[i]])
}

message("Running DpFrEP")

all_strat_pval <- lapply(PCC, function(x)get_all_strat_pval(exp_mtx, rand_mtx, x))
drug_efficacy <- lapply(all_strat_pval, get_drug_efficacy)

message("Writing output file")

for (i in seq_along(drug_efficacy)) drug_efficacy[[i]]$model <- names(drug_efficacy)[i]
drug_efficacy <- Reduce(rbind, drug_efficacy)

meta <- read.csv(file = here("dpfrep", "data", "drug_meta.csv"), check.names = F, stringsAsFactors = F)
drug_efficacy <- cbind(drug_efficacy, meta[match(drug_efficacy$drug.id, meta$drug.id), seq_along(meta)[-1]])

drug_efficacy <- drug_efficacy[order(drug_efficacy$`G-value`),]
drug_efficacy <- split(drug_efficacy[, seq_along(drug_efficacy)[-1]], drug_efficacy$sample.id)

write.xlsx(drug_efficacy, file = paste("Drug_predictions_", Sys.time(), ".xlsx", sep = ''))
