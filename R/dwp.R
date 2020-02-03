#' Concentric non-overpaping rings.
#' @description The \code{dwp} function will create the table with Density Weighted Probability
#' required to run  \code{genest}.
#'
#' @param vr a shapefile describing the visibility for each turbine at each ring. Ideally should
#' be obtained with \code{virings}.
#'
#' @param pt a shapefile with carcass positions with an unique ID for each one.
#'
#' @return a data.frame with dwp for each turbine at each ring distance.
#'
#' @details Ensure that pt is a vector with the group you are interested in.
#'
#' @author Paulo E. Cardoso
#'
#' @import sf
#' @import tidyverse
#' @examples
#' # not run
#' ags <- st_sfc(st_point(c(1,2)), st_point(c(200,200)))
#' ags <- st_sf(geometry = ags) %>%
#' st_set_crs(3763) %>%
#' mutate(ag = 1:2)
#'
#' # Distaces for concentric rings
#' dist = units::set_units(c(10, 20, 30, 40, 50, 100), m)
#'
#' rings <- vrings(x = ags, d = dist)
#'
#' # Carcass distritubion
#' logs <- st_sample(st_buffer(ags, 50), 10, type = "random", exact = TRUE) %>%
#'   st_sf(.)
#' logs$idu <- 1:5
#'
#' ggplot() +
#'   geom_sf(aes(fill = as.numeric(dist), colour = factor(ag)),
#'           size = 1.1,
#'           data = rings) +
#'   geom_sf(data = logs)
#'
#' # obtain dwp data.frame
#' dfdwp <- dwp(vr = rings, pt = logs)
#'
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
