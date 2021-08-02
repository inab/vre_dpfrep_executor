if (!require("librarian"))
  install.packages("librarian", repos = "https://cloud.r-project.org/")
librarian::shelf(fastmatch, fgsea, openxlsx, reshape2, cran_repo = "https://cloud.r-project.org/")

message("STARTING DRUG PREDICTION PROCESS")

message("Reading input arguments:")

args <- commandArgs(trailingOnly = T)
input_file <- args[1]
tumor_type <- args[2]
model_name <- args[3]
parent_dir <- args[4]
functions_dir <- paste(parent_dir, "dpfrep/dpfrep_functions.R", sep = '/')

source(functions_dir)

message(paste("\t- expression matrix:", input_file, sep = " "))
message(paste("\t- tumor type:", tumor_type, sep = " "))
message(paste("\t- model name:", model_name, sep = " "))

exp_mtx <- as.matrix(read.csv(
  file = input_file,
  check.names = F,
  row.names = 1,
  stringsAsFactors = F
))

message("Generating randomized expression profiles")

time <- ceiling(10000 / ncol(exp_mtx))
rand_mtx <- do.call(cbind, replicate(time, exp_mtx, simplify = F))

dms <- prod(dim(rand_mtx))
thr <- round(dms * 0.25)

set.seed(123)
idx <- sample(1:dms, thr)
rand_mtx[idx] <- sample(rand_mtx[idx])
colnames(rand_mtx) <- paste0('rand', seq_len(ncol(rand_mtx)))

message("Importing model(s)")

if (model_name == 'Ensemble')
  model_name <- c('Broad', 'Sanger')

PCC <- vector(mode = 'list', length = length(model_name))
names(PCC) <- model_name

for (i in model_name) {
  root <- paste(parent_dir, "dpfrep/data", tumor_type, i, sep = '/')
  all_rds <- list.files(root)
  PCC[[i]] <- vector(mode = 'list', length = length(all_rds))
  for (j in seq_along(all_rds)) {
    PCC[[i]][[j]] <- readRDS(paste(root, all_rds[j], sep = '/'))
  }
  PCC[[i]] <- do.call(rbind, PCC[[i]])
}

message("RUNNING DRUG PREDICTION")

all_strat_pval <- lapply(PCC, function(x)
  get_all_strat_pval(exp_mtx, rand_mtx, x))
drug_efficacy <- lapply(all_strat_pval, get_drug_efficacy)

for (i in seq_along(drug_efficacy))
  drug_efficacy[[i]]$model <- names(drug_efficacy)[i]
drug_efficacy <- Reduce(rbind, drug_efficacy)

meta_file <- paste(parent_dir, "dpfrep/data/drug_meta.csv", sep = '/')
meta <- read.csv(file = meta_file,
                 check.names = F,
                 stringsAsFactors = F)

drug_efficacy <- cbind(drug_efficacy, meta[match(drug_efficacy$drug.id, meta$drug.id), seq_along(meta)[-1]])
drug_efficacy <- drug_efficacy[order(drug_efficacy$`G-value`),]
drug_efficacy <- split(drug_efficacy[, seq_along(drug_efficacy)[-1]], drug_efficacy$sample.id)

file_xlsx <- paste0("Drug_predictions_", Sys.time(), ".xlsx")
write.xlsx(drug_efficacy, file = file_xlsx)

message(paste(
  "DRUG PREDICTION ended successfully; see results",
  normalizePath(file_xlsx),
  sep = " "
))

message("FINISHING DRUG PREDICTION PROCESS")