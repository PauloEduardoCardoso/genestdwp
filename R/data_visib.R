#' Shapefile with fake visibility map.
#'
#'
#' @format A shapefile with 4 columns:
#' \describe{
#'   \item{ag}{unique turbine id}
#'   \item{dist}{distance ring}
#'   \item{vis}{visibility class (0 to 6)
#'   \item{area}{area (m^2) of the corresponging cross section}
#' }
#' @source QGIS
#' @author Paulo E. Cardoso
#' @examples
#' \dontrun{
#' data(visib)
#' summary(visib)
#' }
"visib"
