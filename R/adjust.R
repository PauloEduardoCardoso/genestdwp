#' Correct carcass to nearest visible patch.
#' @description The \code{adjust} function will adjust the carcass position when its position
#' is over a not searched or not visible patch. Misplaced carcasses can happens due to gps
#' bad fix. Correcting positions will be relevant to correctly estimate DWP.
#' @param ring a shapefile describing the visibility for each turbine.
#' @param pto a vector of found carcasses.
#' @return a sf object.
#' @details ensure that ring is a vector with the columns ag, dist and vis.
#' @author Paulo E. Cardoso
#' @import sf
#' @import tidyverse
#' @examples
#' # not run
#' ring <- viring(x, d)
#' adjust(pto, ring)
#' @export
adjust <- function(pto, ring){
  adj <- st_join(pto, ring, join = st_nearest_feature)
  return(adj)
}
