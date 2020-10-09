library(mosaic)
library(fgsea)
library(reshape2)
library(prodlim)
library(openxlsx)

source('/home/user/vre_dpfrep_executor/lib/dpfrep_functions.R')


message("STARTING DRUG PREDICTION PROCESS")

message("Reading input arguments")
args = commandArgs(trailingOnly = TRUE)
if(length(args)!=4){
  print("Please supply all arguments.")
}

input_file = args[1]
reference_ids = args[2] 
tumor_type = args[3]
return_stdz_ES = as.logical(args[4])

exp_mtx <- as.matrix(read.csv(file = input_file, check.names = F, row.names = 1, stringsAsFactors = F))
reference_ids <- strsplit(reference_ids,',')[[1]]
reference_ids <- intersect(reference_ids,colnames(exp_mtx))

if(reference_ids!='NULL'){
  message('Computing z-scores')
  reference_ids <- strsplit(readLines(reference_ids),',')[[1]]
  condition_ids <- setdiff(colnames(exp_mtx),reference_ids)
  exp_mtx <- sapply(condition_ids,function(i)apply(exp_mtx[,c(i,reference_ids)],1,mosaic::zscore)[1,])
}

message("Running DpFrEP") 

PCC <- readRDS(paste('rds/PCC_',tumor_type,'.rds',sep=''))

all_met <- get_all_met(exp_mtx,PCC,standardize = return_stdz_ES)
cons <- lapply(all_met,get_consensus)


message("Writing output file")

for(i in names(cons)) write.xlsx(cons[[i]],file=paste('Predictions_for_',i,'_dataset.xlsx',sep=''))
