#' crossing  visibility with concentric rings.
#' @description The \code{virings} function will create a new layer crossing the visibility
#' mapped with concentric and non-overpaping rings for each turbine. Centroids are obtained from
#' the mapped area that will be ideally be built using the \code{rings}
#'
#' @param x a shapefile describing the visibility for each turbine.
#'
#' @param d a vector of distances to build concentric rings aroung each mapped area.
#'
#' @return a sf object.
#'
#' @details ensure that d is a vector with distances, regular or not. Your visibility layer must
#' have the columns [ag] and [vis].
#'
#' @author Paulo E. Cardoso
#'
#' @import sf
#' @import tidyverse
#' @examples
#' # not run
#' rings <- viring(x, d)
#'
#' ggplot() +
#'   geom_sf(aes(fill = as.numeric(area), colour = factor(ag)),
#'          size = .5,
#'           data = rings) +
#'   geom_sf(data = logs)
#'
#' dfdwp <- dwp(vr = rings, pt = logs)'
#' @export
viring <- function(x, d){
  `%notin%` <- Negate(`%in%`)
  # check dist
  if (is.null(d)){
    stop("d deve ser um vetor com distancias")
  }

  # check names
  if (any(c('ag', 'vis') %notin% names(x))){
    stop("colunas devem ser [ag] e [vis]!")
  }
  xint <- x %>%
    group_by(ag) %>%
    summarise(id = 1) %>% # unite to a geometry object
    st_centroid()

  # Rings from visibility centroids
  bint <- purrr::map(d,
                     ~st_buffer(xint, .x) %>%
                       mutate(dist = .x,
                              ag = xint$ag)
  ) %>%
    do.call("rbind", .) %>%
    st_cast() %>%
    st_difference(.)
  bint$area <- st_area(bint)

  # Visibility area crossed with rings
  bvisib <- bint %>% st_intersection(x)
  bvisib$area <- st_area(bvisib)

  return(bvisib)

}

