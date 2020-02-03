#' cross  visibility map with concentric rings.
#' @description The \code{virings} function will create a new layer resulting from crossing the
#' mapped visibility with concentric-and-non-overpaping rings for each mapped area around
#' turbines. Centroids are obtained from the visibility map.
#' Visibility map can be built from buffer areas resulting from \code{sf::st_buffer} function.
#'
#' @param x a shapefile describing the visibility mapped for each turbine.
#'
#' @param d a vector of distances to build concentric rings aroung each mapped area.
#'
#' @return a sf object.
#'
#' @details ensure that d is a vector with distances, single, regularly spaced or not.
#' Your visibility layer must have at least two columns: ag and vis.
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
#' dfdwp <- dwp(vr = rings, pt = logs)
#' @export
viring <- function(x, d){
  `%notin%` <- Negate(`%in%`)
  # check dist
  if (is.null(d)){
    stop("d deve ser um vetor com distancias")
  }

  # check names
  if (any(c('ag', 'vis') %notin% names(x))){
    stop("visibility layer must contain at least the columns [ag] and [vis]!")
  }
  xint <- x %>%
    group_by(ag) %>%
    summarise(id = 1) %>%
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
