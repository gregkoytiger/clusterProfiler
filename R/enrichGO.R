##' GO Enrichment Analysis of a gene set.
##' Given a vector of genes, this function will return the enrichment GO
##' categories after FDR control.
##'
##'
##' @param gene a vector of entrez gene id.
##' @param OrgDb OrgDb
##' @param keytype keytype of input gene
##' @param ont One of "MF", "BP", and "CC" subontologies.
##' @param pvalueCutoff Cutoff value of pvalue.
##' @param pAdjustMethod one of "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr", "none"
##' @param universe background genes
##' @param qvalueCutoff qvalue cutoff
##' @param minGSSize minimal size of genes annotated by Ontology term for testing.
##' @param readable whether mapping gene ID to gene Name
##' @return A \code{enrichResult} instance.
##' @importClassesFrom DOSE enrichResult
##' @importMethodsFrom DOSE show
##' @importMethodsFrom DOSE summary
##' @importMethodsFrom DOSE plot
##' @importFrom DOSE setReadable
##' @seealso \code{\link{enrichResult-class}}, \code{\link{compareCluster}}
##' @keywords manip
##' @export
##' @author Guangchuang Yu \url{http://ygc.name}
##' @examples
##' \dontrun{
##' 	data(gcSample)
##' 	yy <- enrichGO(gcSample[[1]], 'org.Hs.eg.db', ont="BP", pvalueCutoff=0.01)
##' 	head(summary(yy))
##' 	plot(yy)
##' }
enrichGO <- function(gene,
                     OrgDb,
                     keytype = "ENTREZID",
                     ont="MF",
                     pvalueCutoff=0.05,
                     pAdjustMethod="BH",
                     universe,
                     qvalueCutoff = 0.2,
                     minGSSize = 5,
                     readable=FALSE) {

    ont %<>% toupper
    ont <- match.arg(ont, c("BP", "CC", "MF", "ALL"))

    GO_DATA <- get_GO_data(OrgDb, ont, keytype)
    
    res <- enricher_internal(gene,
                             pvalueCutoff=pvalueCutoff,
                             pAdjustMethod=pAdjustMethod,
                             universe = universe,
                             qvalueCutoff = qvalueCutoff,
                             minGSSize = minGSSize,
                             USER_DATA = GO_DATA
                             )

    if (is.null(res))
        return(res)
    
    res@keytype <- keytype
    res@organism <- get_organism(OrgDb)
    if(readable) {
        res <- setReadable(res, OrgDb)
    }
    res@ontology <- ont
    
    if (ont == "ALL") {
        res <- add_GO_Ontology(res, GO_DATA)
    }
    return(res)
}


##' @importFrom DOSE load_OrgDb
##' @importFrom AnnotationDbi keys
##' @importFrom AnnotationDbi select
##' @importFrom AnnotationDbi keytypes
##' @importFrom AnnotationDbi toTable
##' @importFrom GO.db GOTERM
get_GO_data <- function(OrgDb, ont, keytype) {
    GO_Env <- get_GO_Env()
    use_cached <- FALSE

    if (exists("organism", envir=GO_Env, inherits=FALSE) &&
        exists("keytype", envir=GO_Env, inherits=FALSE)) {

        org <- get("organism", envir=GO_Env)
        kt <- get("keytype", envir=GO_Env)
        
        if (org == get_organism(OrgDb) &&
            keytype == kt &&
            exists("goAnno", envir=GO_Env, inherits=FALSE) &&
            exists("GO2TERM", envir=GO_Env, inherits=FALSE)){
            
            use_cached <- TRUE
        }
    }
    
    if (use_cached) {
        goAnno <- get("goAnno", envir=GO_Env)
        GO2TERM <- get("GO2TERM", envir=GO_Env)
    } else {
        OrgDb <- load_OrgDb(OrgDb)
        kt <- keytypes(OrgDb)
        if (! keytype %in% kt) {
            stop("keytype is not supported...")
        }
        
        kk <- keys(OrgDb, keytype=keytype)    
        goAnno <- suppressMessages(
            select(OrgDb, keys=kk, keytype=keytype,
                   columns=c("GOALL", "ONTOLOGYALL")))
        
        goids <- toTable(GOTERM)
        GO2TERM <- goids[, c("go_id", "Term")] %>% unique
        assign("goAnno", goAnno, envir=GO_Env)
        assign("GO2TERM", GO2TERM, envir=GO_Env)
        assign("keytype", keytype, envir=GO_Env)
        assign("organism", get_organism(OrgDb), envir=GO_Env)
    }
    
    if (ont == "ALL") {
        GO2GENE <- goAnno[, c(2,1)]
    } else {    
        GO2GENE <- goAnno[goAnno$ONTOLOGYALL == ont, c(2,1)]
    }
    
    GO_DATA <- build_Anno(GO2GENE, GO2TERM)
    
    goOnt.df <- goAnno[, c("GOALL", "ONTOLOGYALL")] %>% unique
    goOnt <- goOnt.df[,2]
    names(goOnt) <- goOnt.df[,1]
    assign("GO2ONT", goOnt, envir=GO_DATA)
    return(GO_DATA)
}

get_GO_Env <- function () {
    if (!exists("GO_clusterProfiler_Env", envir = .GlobalEnv)) {
        assign("GO_clusterProfiler_Env", new.env(), .GlobalEnv)
    }
    get("GO_clusterProfiler_Env", envir = .GlobalEnv)
}


## ##' @importMethodsFrom AnnotationDbi Ontology
## ##' @importFrom GO.db GOTERM
## ##' @importMethodsFrom AnnotationDbi mappedkeys
## ##' @importFrom plyr dlply
## ##' @importFrom plyr .
## ##' @importClassesFrom methods data.frame
## EXTID2TERMID.GO <- function(gene, ont, organism) {

##     gene <- as.character(gene)

##     ## get all goterms within the specific ontology
##     goterms <- Ontology(GOTERM)
##     goterms <- names(goterms[goterms == ont])

##     supported_Org <- getSupported_Org()
##     if (organism %in% supported_Org) {
##         mappedDb <- getGO2ALLEG_MappedDb(organism)

##         orgTerm <- mappedkeys(mappedDb)

##         ## narrow down goterms to specific organism
##         Terms <- goterms[goterms %in% orgTerm]

##         ## mapping GO to External gene ID
##         class(Terms) <- ont
##         GO2ExtID <- TERMID2EXTID(Terms, organism)


##         qGO2ExtID = lapply(GO2ExtID, function(i) gene[gene %in% i])
##         len <- sapply(qGO2ExtID, length)
##         notZero.idx <- len != 0
##         qGO2ExtID <- qGO2ExtID[notZero.idx]

##         len <- sapply(qGO2ExtID, length)
##         qGO2ExtID.df <- data.frame(GO=rep(names(qGO2ExtID), times=len),
##                                    ExtID=unlist(qGO2ExtID))

##         ExtID <- NULL ## to satisfy codetools
##         qExtID2GO <- dlply(qGO2ExtID.df, .(ExtID), function(i) as.character(i$GO))
##     } else {
##         oldwd <- getwd()

##         if (file.exists("EG2ALLGO.rda")) {
##             EG2ALLGO <- NULL # to satisfy codetools
##             load("EG2ALLGO.rda")
##             qExtID2GO <- EG2ALLGO[gene]
##             qExtID2GO <- lapply(qExtID2GO, function(i) i[i %in% goterms])
##         } else if (organism == "D39") {            
##             dir <- system.file("extdata/D39/", package="clusterProfiler")
##             setwd(dir)
##         } else if (organism == "M5005") {
##             dir <- system.file("extdata/M5005/", package="clusterProfiler")
##             setwd(dir)
##         } else {
##             setwd(oldwd)
##             stop("GO mapping files not found in the working directory")
##         }
        
##         setwd(oldwd)
##     }
##     return(qExtID2GO)
## }

## ##' @importMethodsFrom AnnotationDbi mget
## ##' @importFrom GOSemSim getSupported_Org
## TERMID2EXTID.GO <- function(term, organism, ...) {
##     term <- as.character(term)

##     GO2ALLEG <- GO2EXTID(organism)
##     if (is(GO2ALLEG, "Go3AnnDbBimap")) {
##         GO2ExtID <- mget(term, GO2ALLEG, ifnotfound=NA)
##         GO2ExtID <- lapply(GO2ExtID, function(i) unique(i))
##     } else {
##         GO2ExtID <- GO2ALLEG[term]
##     }
##     return(GO2ExtID)
## }

## GO2EXTID <- function(organism) {
##     supported_Org <- getSupported_Org()
##     if (organism %in% supported_Org) {
##         GO2ALLEG <- getGO2ALLEG_MappedDb(organism)
##     } else {
##         oldwd <- getwd()
##         if(organism == "D39") {
##             dir <- system.file("extdata/D39/", package="clusterProfiler")
##             setwd(dir)
##         }
##         if(organism == "M5005") {
##             dir <- system.file("extdata/M5005/", package="clusterProfiler")
##             setwd(dir)
##         }
##         if (file.exists("GO2ALLEG.rda")) {
##             GO2ALLEG <- NULL # to satisfy codetools
##             load("GO2ALLEG.rda")
##         } else {
##             setwd(oldwd)
##             stop("GO Mapping file not found in the working directory")
##         }
##         setwd(oldwd)
##     }
##     return(GO2ALLEG)
## }

## ##' @importMethodsFrom AnnotationDbi mappedkeys
## ##' @importFrom GOSemSim getSupported_Org
## ALLEXTID.GO <- function(organism) {
##     supported_Org <- getSupported_Org()
##     if (organism %in% supported_Org) {
##         mappedDb <- getEG2GO_MappedDb(organism)
##         extID <- mappedkeys(mappedDb)
##     } else {
##         oldwd <- getwd()
##         if(organism == "D39") {
##             dir <- system.file("extdata/D39/", package="clusterProfiler")
##             setwd(dir)
##         }
##         if(organism == "M5005") {
##             dir <- system.file("extdata/M5005/", package="clusterProfiler")
##             setwd(dir)
##         }
##         if (file.exists("EG2ALLGO.rda")) {
##             EG2ALLGO <- NULL ## to satisfy codetools
##             load("EG2ALLGO.rda")
##             extID <- names(EG2ALLGO)
##         } else {
##             setwd(oldwd)
##             stop("GO mapping file not found in the working directory")
##         }
##         setwd(oldwd)
##     }
##     return(extID)
## }


##' drop GO term of specific level or specific terms (mostly too general).
##'
##' 
##' @title dropGO
##' @param x an instance of 'enrichResult' or 'compareClusterResult'
##' @param level GO level
##' @param term GO term
##' @return modified version of x
##' @importFrom GO.db GOTERM
##' @importFrom AnnotationDbi Ontology
##' @export
##' @author Guangchuang Yu
dropGO <- function(x, level=NULL, term=NULL) {
    if (! (is(x, "enrichResult") || is(x, "compareClusterResult")) ) {
        stop("x should be an instance of 'enrichResult' or 'compareClusterResult' ...")
    }
    
    if (!is.null(level)) {
        if (is(x, "enrichResult")) {
            ont <- x@ontology
        } else {
            ont <- x@.call$ont
            if (is.null(ont)) {
                ## should be "MF", default value of enrichGO
                ## it's safe to determine from the output
                ont <- x@compareClusterResult$ID[1] %>% GOTERM[[.]] %>% Ontology                
            }
            
        }
        
        tt <- getGOLevel(ont, level)
        term <- c(term, tt) %>% unique
    }
    if (is.null(term)) 
        return(x)
    
    if (is(x, "enrichResult")) {
        gc <- x@geneInCategory
        x@geneInCategory <- gc[!names(gc) %in% term]
        
        res <- x@result
        res <- res[!res$ID %in% term, ]
        x@result <- res
    } else {
        res <- x@compareClusterResult
        res <- res[!res$ID %in% term,]
        x@compareClusterResult <- res
    }
    
    return(x)
}
