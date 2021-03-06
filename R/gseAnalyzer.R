##' Gene Set Enrichment Analysis of Gene Ontology
##'
##'
##' @title gseGO
##' @param geneList order ranked geneList
##' @param ont one of "BP", "MF", "CC" or "GO"
##' @param OrgDb OrgDb
##' @param keytype keytype of gene
##' @param exponent weight of each step
##' @param nPerm permutation numbers
##' @param minGSSize minimal size of each geneSet for analyzing
##' @param pvalueCutoff pvalue Cutoff
##' @param pAdjustMethod pvalue adjustment method
##' @param verbose print message or not
##' @param seed logical
##' @importClassesFrom DOSE gseaResult
##' @importMethodsFrom DOSE show
##' @importMethodsFrom DOSE summary
##' @importMethodsFrom DOSE plot
##' @export
##' @return gseaResult object
##' @author Yu Guangchuang
gseGO <- function(geneList,
                  ont           = "BP", 
                  OrgDb,
                  keytype       = "ENTREZID",
                  exponent      = 1,
                  nPerm         = 1000,
                  minGSSize     = 10,
                  maxGSSize     = 500,
                  pvalueCutoff  = 0.05,
                  pAdjustMethod = "BH",
                  verbose       = TRUE,
                  seed          = FALSE) {

    ont %<>% toupper
    ont <- match.arg(ont, c("BP", "CC", "MF", "ALL"))
    
    GO_DATA <- get_GO_data(OrgDb, ont, keytype)

    res <-  GSEA_internal(geneList = geneList,
                          exponent = exponent,
                          nPerm = nPerm,
                          minGSSize = minGSSize,
                          maxGSSize = maxGSSize,
                          pvalueCutoff = pvalueCutoff,
                          pAdjustMethod = pAdjustMethod,
                          verbose = verbose,
                          USER_DATA = GO_DATA,
                          seed = seed)

    if (is.null(res))
        return(res)
    
    res@organism <- get_organism(OrgDb)
    res@setType <- ont
    res@keytype <- keytype
    
    if (ont == "ALL") {
        res <- add_GO_Ontology(res, GO_DATA)
    } 
    return(res)
}


##' Gene Set Enrichment Analysis of KEGG Module
##'
##'
##' @title gseMKEGG
##' @param geneList order ranked geneList
##' @param organism supported organism listed in 'http://www.genome.jp/kegg/catalog/org_list.html'
##' @param exponent weight of each step
##' @param nPerm permutation numbers
##' @param minGSSize minimal size of each geneSet for analyzing
##' @param pvalueCutoff pvalue Cutoff
##' @param pAdjustMethod pvalue adjustment method
##' @param verbose print message or not
##' @param seed logical
##' @export
##' @return gseaResult object
##' @author Yu Guangchuang
gseMKEGG <- function(geneList,
                     organism          = 'hsa',
                     exponent          = 1,
                     nPerm             = 1000,
                     minGSSize         = 10,
                     maxGSSize         = 500,
                     pvalueCutoff      = 0.05,
                     pAdjustMethod     = "BH",
                     verbose           = TRUE,
                     seed = FALSE) {

    species <- organismMapper(organism)    
    KEGG_DATA <- download.KEGG(species, "MKEGG")

    res <-  GSEA_internal(geneList = geneList,
                          exponent = exponent,
                          nPerm = nPerm,
                          minGSSize = minGSSize,
                          maxGSSize = maxGSSize,
                          pvalueCutoff = pvalueCutoff,
                          pAdjustMethod = pAdjustMethod,
                          verbose = verbose,
                          USER_DATA = KEGG_DATA,
                          seed = seed)

    if (is.null(res))
        return(res)

    
    res@organism <- species
    res@setType <- "MKEGG"
    res@keytype <- "UNKNOWN"
    
    return(res)
}


##' Gene Set Enrichment Analysis of KEGG
##'
##'
##' @title gseKEGG
##' @inheritParams gseMKEGG
##' @param use_internal_data logical, use KEGG.db or latest online KEGG data
##' @importClassesFrom DOSE gseaResult
##' @importMethodsFrom DOSE show
##' @importMethodsFrom DOSE summary
##' @importMethodsFrom DOSE plot
##' @export
##' @return gseaResult object
##' @author Yu Guangchuang
gseKEGG <- function(geneList,
                    organism          = 'hsa',
                    exponent          = 1,
                    nPerm             = 1000,
                    minGSSize         = 10,
                    maxGSSize         = 500,
                    pvalueCutoff      = 0.05,
                    pAdjustMethod     = "BH",
                    verbose           = TRUE,
                    use_internal_data = FALSE,
                    seed              = FALSE) {

    species <- organismMapper(organism)
    if (use_internal_data) {
        KEGG_DATA <- get_data_from_KEGG_db(species)
    } else {
        KEGG_DATA <- download.KEGG(species, "KEGG")
    }

    res <-  GSEA_internal(geneList = geneList,
                          exponent = exponent,
                          nPerm = nPerm,
                          minGSSize = minGSSize,
                          maxGSSize = maxGSSize,
                          pvalueCutoff = pvalueCutoff,
                          pAdjustMethod = pAdjustMethod,
                          verbose = verbose,
                          USER_DATA = KEGG_DATA,
                          seed = seed)

    if (is.null(res))
        return(res)
    
    res@organism <- species
    res@setType <- "KEGG"
    res@keytype <- "UNKNOWN"
    
    return(res)
}

##' visualize analyzing result of GSEA
##'
##' plotting function for gseaResult
##' @title gseaplot
##' @param gseaResult gseaResult object
##' @param geneSetID geneSet ID
##' @param by one of "runningScore" or "position"
##' @return ggplot2 object
##' @export
##' @author ygc
gseaplot <- DOSE::gseaplot


