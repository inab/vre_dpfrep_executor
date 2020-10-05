get_ptw_list<-function(CCLs_expr,corr_mat,limit){
  idx_CCLs <- rownames(CCLs_expr)%in%rownames(corr_mat)
  CCLs_expr <- CCLs_expr[idx_CCLs,]
  
  CCLs_signature <- vector(mode = 'list', length = ncol(CCLs_expr))
  names(CCLs_signature) <- colnames(CCLs_expr)
  
  for(i in colnames(CCLs_expr)){
    CCLs_signature[[i]] <- vector(mode = 'list', length = 2)
    names(CCLs_signature[[i]]) <- c('up_genes','down_genes')
    
    expr_val <- CCLs_expr[!is.na(CCLs_expr[,i]),i]
    sorted_genes <- names(sort(expr_val,decreasing=T))
    
    CCLs_signature[[i]]$up_genes <- sorted_genes[1:limit]
    CCLs_signature[[i]]$down_genes <- rev(sorted_genes)[1:limit]
  }
  
  CCLs_signature <- unlist(CCLs_signature,recursive = F)
  return(CCLs_signature)
}


compute_gsea <- function(ptw_l,corr_mat){
  res <- matrix(nrow = length(ptw_l),ncol = ncol(corr_mat),dimnames = list(names(ptw_l),colnames(corr_mat)))
  for (i in 1:length(ptw_l)){
    for(j in 1:ncol(corr_mat)){
      sorted_mrks <- sort(corr_mat[,j],decreasing=T)
      sel_mrks <- fastmatch::fmatch(ptw_l[[i]],names(sorted_mrks))
      res[i,j] <- calcGseaStat(stats = sorted_mrks,selectedStats = sel_mrks,gseaParam = 0)
    }
  }
  return(res)
}


get_single_ES <- function(stat,direction='down',sensitivity = TRUE){
  ES <- reshape2::melt(stat)
  idx <- grep(paste(direction,'_genes',sep=''),ES$Var1)
  ES <- ES[idx,]
  ES$Var1 <- gsub(paste('.',direction,'_genes',sep=''),'',ES$Var1)
  if(all(grepl('DRUG',ES[,1]))) ES <- ES[,c(2:1,3:4)]
  colnames(ES) <- c('sample.id','drug.id','value','center')
  if (direction=='down') ES <- ES[order(ES$value,decreasing = T),]
  else ES <- ES[order(ES$value),]
  if(!sensitivity) ES <- ES[nrow(ES):1,]
  ES[,1:2] <- lapply(ES[,1:2], as.character)
  return(split(ES[,1:3],ES$center))
}


drug_normlz <- function(x){
  id <- sort(unique(x[[1]]))
  drug <- sort(unique(x[[2]]))
  
  mtx<- matrix(0,nrow=length(id),ncol=length(drug),dimnames = list(id,drug))
  mtx[as.matrix(x[,1:2])]<-x[,3]
  
  norm_mtx <- apply(mtx,2,mosaic::zscore)
  
  new_x <- reshape2::melt(norm_mtx,varnames = names(x)[1:2])
  
  i <- sapply(new_x, is.factor)
  new_x[i] <- lapply(new_x[i], as.character)
  
  if(!is.unsorted(x$value))new_x<-new_x[order(new_x$value),]
  else new_x <- new_x[order(new_x$value,decreasing=T),]
  
  return(new_x)
}


get_all_met <- function(exp_mtx,PCC,standardize=F){
  gsea_CCL_drug <- gsea_drug_CCL <- vector(mode='list')
  for(i in names(PCC)){
    
    ### Get signatures of up and down-regulated genes from expression profiles of CCLs
    
    ptw_list <- get_ptw_list(exp_mtx,PCC[[i]],limit=250)
    mrk_list <- get_ptw_list(PCC[[i]],exp_mtx,limit=250)
    
    ### Get Enrichment Scores (ES)
    
    gsea_CCL_drug[[i]] <- compute_gsea(ptw_l = ptw_list,corr_mat = PCC[[i]])
    gsea_drug_CCL[[i]] <- compute_gsea(ptw_l = mrk_list,corr_mat = exp_mtx)
  }
  
  a <- get_single_ES(gsea_CCL_drug, direction = 'up')
  b <- get_single_ES(gsea_CCL_drug)
  c <- get_single_ES(gsea_drug_CCL)
  d <- get_single_ES(gsea_drug_CCL, direction='up')
  
  sng_met <- mapply('list',a,b,c,d,SIMPLIFY=F)
  for (i in seq_along(sng_met)) names(sng_met[[i]]) <- letters[1:4]

  if(standardize){
    sng_met <- lapply(sng_met,function(x)lapply(x,drug_normlz))
  }

  return(sng_met)
}


get_consensus <- function(all_met){
  for(i in 1:length(all_met)){
    all_met[[i]]$value <- 1:nrow( all_met[[i]])
    if(i==1) x <- all_met[[i]]
    else if(i >1){
      idx <- prodlim::row.match(x[,1:2],all_met[[i]][,1:2])
      x <- cbind(x,all_met[[i]][idx,'value'])
    }
  }
  cons<-data.frame(x[,1:2],value=rowMeans(x[,3:ncol(x)]))
  cons <- cons[order(cons$value),]
  meta <- read.csv(file = 'drug_meta.csv', check.names = F, stringsAsFactors = F)
  cons <- cbind(cons,meta[match(cons$drug.id,meta$drug.id),seq_along(meta)[-1]])
  cons <- split(cons[,seq_along(cons)[-1]],cons$sample.id)
  for (i in seq_along(cons))cons[[i]]$value <- rank(cons[[i]]$value,ties.method = 'random')
  return(cons)
}