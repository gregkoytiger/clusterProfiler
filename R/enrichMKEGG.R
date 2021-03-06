##' KEGG Module Enrichment Analysis of a gene set.
##' Given a vector of genes, this function will return the enrichment KEGG Module
##' categories with FDR control.
##'
##'
##' @inheritParams enrichKEGG
##' @return A \code{enrichResult} instance.
##' @export
enrichMKEGG <- function(gene,
                        organism = 'hsa',
                        pvalueCutoff = 0.05,
                        pAdjustMethod = 'BH',
                        universe,
                        minGSSize = 5,
                        qvalueCutoff = 0.2) {

    species <- organismMapper(organism)
    KEGG_DATA <- download.KEGG(species, "MKEGG")
    res <- enricher_internal(gene,
                             pvalueCutoff  =pvalueCutoff,
                             pAdjustMethod =pAdjustMethod,
                             universe      = universe,
                             minGSSize     = minGSSize,
                             qvalueCutoff  = qvalueCutoff,
                             USER_DATA = KEGG_DATA)

    if (is.null(res))
        return(res)
    
    
    res@ontology <- "MKEGG"
    res@organism <- species
    res@keytype <- "UNKNOWN"
    
    return(res)
}
