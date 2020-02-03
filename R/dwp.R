#' Concentric non-overpaping rings.
#' @description The \code{virings} function will create a new layer crossing the visibility
#' mapped with concentric and non-overpaping rings for each turbine. Centroids are obtained from
#' the mapped area that will be ideally be built using the \code{rings}
#'
#' @param vr a shapefile describing the visibility for each turbine.
#'
#' @param pt a vector of distances to build concentric rings aroung each mapped area.
#'
#' @return a sf object.
#'
#' @details ensure that d is a vector with distances, regular or not. Your visibility layer must
#' have the columns ag and vis.
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
dwp <- function(vr, pt){
  # check names vring
  if (any(c('ag', 'vis', 'dist') %notin% names(vr))){
    stop("colunas devem ser [ag] [dist] [vis]!")
  }
  # check names pt
  if (any(c('idu') %notin% names(pt))){
    stop("colunas devem ser [ag] e [vis]!")
  }

  # Step 1.1 Carcass at each ring dist ####
  cr <- logs %>% st_intersection(vr) %>%
    st_drop_geometry() %>%
    group_by(dist) %>%
    tally(n())
  # Obtaining pmi
  int <- vr %>%
    st_drop_geometry() %>%
    filter(as.numeric(dist) <= 50) %>%
    group_by(dist) %>%
    summarise(tarea = sum(area)) %>%
    ungroup() %>%
    # Relative mortality per ring dist (Mi)
    left_join(vr %>%
                st_drop_geometry() %>%
                filter(vis > 0) %>%
                group_by(dist) %>%
                summarise(varea = sum(area)),
              by = c('dist' = 'dist')) %>%
    ungroup() %>%
    left_join(cr, by = c('dist' = 'dist')) %>%
    mutate(n = ifelse(is.na(n),0,n),
           pr = varea / tarea,
           mi = n/pr,
           s=sum(mi, na.rm = T),
           pmi = mi/s)
  # pmi df
  pmi <- select(int, c('dist', 'pmi'))

  # dwp
  dwp <- rings %>%
    st_drop_geometry() %>%
    group_by(ag, dist) %>%
    summarise(area = sum(area)) %>%
    left_join(
      rings %>%
        st_drop_geometry() %>%
        filter(vis > 0)  %>%
        group_by(ag, dist) %>%
        summarise(area = sum(area)),
      by = c('ag' = 'ag', 'dist' = 'dist')
    ) %>%
    left_join(pmi, by = c('dist' = 'dist')) %>%
    mutate(dwp =  (area.y/area.x) * pmi) %>%
    ungroup()
  dwp <- dwp %>%
    select(ag, dist, dwp) %>%
    pivot_wider(names_from = dist, values_from = dwp)

  return(dwp)

}