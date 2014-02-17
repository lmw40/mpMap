#' Collapse an mpcross object into a binned object
#' 
#' Collapses an mpcross object into bins. Markers are recoded as binned markers (BM) where the genotype at a BM is determined from the haplotypes observed in the founders within the bin. Information on which markers belong to each bin is retained within the output object. 
#' @export
#' @useDynLib mpMap
#' @param object Object of class \code{mpcross}
#' @param method Choice of whether to bin based on recombination fraction or correlation 
#' @return A binned object of class \code{binmpcross}
#' @seealso \code{link{mpexpand}}
#' @note Markers are assigned to a bin if there is zero recombination between any of the markers within the bin (or correlation of 1). Missing values at markers are imputed based on the assumption that the true haplotype within a bin matches one of the founder haplotypes. Patterns matching more than one or none of the founder haplotypes will be coded as NA in the returned object. Bins are collapsed to "bin markers" after missing values are imputed, with each unique founder
#' haplotype being assigned an allele and progeny matching those founder haplotypes assigned the same allele. 

mpcollapse<-function(object, method=c("rf", "cor")) {

  enlist <- function(X) lapply(1:ncol(X), function(j) X[,j])
  
  Matches <- function(x, X) {
    stopifnot(ncol(X) == length(x))
    
    mv <- which(is.na(X), arr.ind = TRUE)
    X[mv] <- x[mv[,2]]
    match(do.call(paste0, enlist(X)), paste(x, collapse=""), 0L)
  }
  
  
  if (missing(method)) method <- "rf"

  if (is.null(object$rf$theta) & method=="rf") 
	stop("Need to estimate recombination fractions first\n")

  if (is.null(object$lg) & is.null(object$map)) {
	cat("Assuming all markers are on the same linkage group\n") 
	object <- mpgroup(object, groups=1) 
  }

  nFounders <- nrow(object$founders)
  nFinals <- nrow(object$finals)
  
  if (is.null(object$lg)) object <- mpgroup(object, groups=length(object$map))

  ## Note that correlation is not ideal as it does not take into
  ## account founder genotypes
  if (method=="cor")
	  dist <- (cor(object$finals, use="pairwise.complete.obs"))^2
  else
	  dist <- mpimputerf(object)$rf$theta
  
  n.chr <- length(unique(object$lg$all.groups))
  nmrkperchr <- table(object$lg$groups)

## Note that we remove recombination fractions - these will need to be 
## re-estimated based on the binned markers. Linkage groups we will 
## just collapse down since we're retaining that information with the bins
## Maps will be removed as the distances may change based on the binned markers. 
  output <- object

  if (!is.null(object$rf)) cat("RF need to be re-estimated based on binned markers\n")
  if (!is.null(object$map)) cat("Map need to be re-estimated based on binned markers\n") 

  binFounders <- binFinals <- list()
  binInfo <- list()
  
  for (i in 1:n.chr) {
    indexGroup <- which(object$lg$groups==i)
    
    ## create bins
    mat <- dist[indexGroup, indexGroup]
    cl.obj <- hclust(as.dist(mat), method="complete")
    cl.obj$height <- round(cl.obj$height, 5)
    binInfo[[i]] <- cutree(cl.obj, h=0)
    nbins <- max(binInfo[[i]])
    
    ## Note that after this there will be a substantial amount of recoding. Do not return original object
    ## within each bin recode genotypes to haplotypes
    binFounders[[i]] <- matrix(nrow=nFounders, ncol=nbins)
    binFinals[[i]] <- matrix(nrow=nFinals, ncol=nbins)
    colnames(binFounders[[i]]) <- colnames(binFinals[[i]]) <- paste("C", i, "B", 1:nbins, sep="")
    rownames(binFounders[[i]]) <- rownames(object$founders)
    rownames(binFinals[[i]]) <- rownames(object$finals)
    
    for (j in 1:nbins) {
      indexBin <- indexGroup[which(binInfo[[i]]==j)]    
      if(length(indexBin)>1) {
        haplotypes <- object$founders[,indexBin]
        uniqueHaps <- unique(haplotypes, MARGIN=1)
        ## impute final haplotypes based on founder haplotypes if possible
        missFinals <- which(apply(object$finals[,indexBin], 1, function(x) any(is.na(x))))
    #    uniqueMissFinals <- unique(object$finals[missFinals, indexBin], MARGIN=1)
        matches <- matrix(nrow=length(missFinals), ncol=nrow(uniqueHaps))
        for (k in 1:nrow(uniqueHaps)) 
            matches[,k] <- Matches(uniqueHaps[k,], object$finals[missFinals, indexBin, drop=F])
        for (k in 1:nrow(uniqueHaps)) {
	    toreplace <- which(matches[,k]==1 & rowSums(matches)==1)
            object$finals[missFinals[toreplace], indexBin] <- matrix(rep(uniqueHaps[k,], length(toreplace)), ncol=ncol(uniqueHaps), byrow=TRUE)
        }
#        matchHap <- vector(length=nrow(uniqueMissFinals))
#        for (k in 1:nrow(uniqueMissFinals)) {
#            tmp <- apply(uniqueHaps, 1, function(x) all(x[which(!is.na(uniqueMissFinals[k,]))]==uniqueMissFinals[k,which(!is.na(uniqueMissFinals[k,]))]))
#            if (sum(tmp)==1) matchHap[k] <- which(tmp) else matchHap[k] <- NA
#            if (!is.na(matchHap[k])) {
#        matchUnique <- apply(object$finals[missFinals, indexBin], 1, 
#                  function(x) all(x[which(!is.na(uniqueMissFinals[k,]))]==uniqueMissFinals[k,which(!is.na(uniqueMissFinals[k,]))]))
#              object$finals[missFinals[which(matchUnique)],indexBin] <- uniqueHaps[matchHap[k],]
#            }  
#        }
        ## Now that we've filled in missing values, should better be able to fill out haps
        binFounders[[i]][, j] <- apply(object$founders[,indexBin], 1, function(x) match(paste(x, collapse=""), do.call(paste0, enlist(uniqueHaps))))
        binFinals[[i]][,j] <- apply(object$finals[,indexBin], 1, function(x) match(paste(x, collapse=""), do.call(paste0, enlist(uniqueHaps))))
      } else {
        binFounders[[i]][,j] <- object$founders[, indexBin]
        binFinals[[i]][,j] <- object$finals[,indexBin]
      }
    }
    binInfo[[i]] <- data.frame(MarkerName=colnames(object$founders)[object$lg$groups==i], bin=binInfo[[i]], group=i, binMarkerName=paste("C", i, "B", binInfo[[i]], sep=""))
  }
  output$founders <- do.call("cbind", binFounders)
  output$finals <- do.call("cbind", binFinals)
  output$bins <- do.call("rbind", binInfo)
   
  ## Collapse down the linkage groups
  output$lg$groups <- rep(1:n.chr, unlist(lapply(binInfo, function(x) max(x$bin))))
  names(output$lg$groups) <- colnames(output$finals)

  class(output) <- c("binmpcross", "mpcross")
  return(output)
}  