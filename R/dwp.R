#' Concentric non-overpaping rings.
#' @description The \code{dwp} function will create the table with Density Weighted Probability
#' required to run \code{genest}.
#'
#' @param vr a shapefile describing the visibility for each turbine at each ring. Ideally should
#' be obtained with \code{virings}.
#'
#' @param pt a shapefile with carcass positions with an unique ID for each one.
#'
#' @return a data.frame with dwp for each turbine at each ring distance.
#'
#' @details DWP will be obtained for a single group. Ensure that pt is a vector with the group size you are interested in.
#'
#' @author Paulo E. Cardoso
#'
#' @import sf
#' @import tidyverse
#' @examples
#' # not run
#' library(genestdwp)
#' library(sf)
#' library(ggplot2)
#' library(tidyverse)
#'
#' # Vector of distances
#' dist = units::set_units(c(10, 20, 30, 40, 50), m)
#'
#' # Spatial join among visibility map and rings
#' rings <- genestdwp::viring(x=visib, d = dist)
#'
#' # Carcasses
#' pto_carcass
#' unique(pto_carcass$tamanho)
#'
#' # Get DWP
#' dfdwp <- dwp(vr = rings, pt = pto_carcass)
#' dfdwp
#'
#' # Plot some data together
#' ggplot() +
#'   geom_sf(aes(fill = as.numeric(dist)), colour = 'black',
#'           size = .8, data = filter(rings, ag == 1)) +
#'   geom_sf(data = filter(pto_carcass, ag == 1)) +
#'   theme_void()
#' @export
dwp <- function(vr, pt){

  #Check projections
  if(any(is.na(st_crs(vr)),is.na(st_crs(pt)))){
    stop('No crs found for one or both layers')
  }

  if(st_crs(vr) != st_crs(pt)){
    stop('Projections differ. Please re-check original GIS layers')
  }

  `%notin%` <- Negate(`%in%`) # negate helper function

  # check names vring
  if (any(c('ag', 'visib', 'dist') %notin% names(vr))){
    stop("Visibility layer must contain the following columns: [ag] [dist] [visib]!")
  }
  # check names pt
  if (any(c('tamanho') %notin% names(pt))){
    stop("layer with carcasses must contain column: [tamanho] !")
  }

  # Step 1.1 Carcass at each ring dist ####
  cr <- pt[ ,-1] %>%
    st_join(select(vr, ag, dist, visib), join = st_intersects) %>%
    filter(!is.na(visib))

  if(nrow(filter(cr, visib == 0)) != 0){
    print('Attention!')
    print(st_drop_geometry(filter(select(cr, ag, visib), visib == 0)))
    print(paste('Found n =',
                  nrow(filter(cr, visib == 0)),
                  'carcasses on visibility = 0! Assuming value of nearest visible area'))
    cr <- cr %>%
      st_join(filter(rings, visib != 0), join = st_nearest_feature)
    cr <- select(cr, tamanho, ag = ag.x, dist = dist.y, visib = visib.y)
  }
  cr <- cr %>%
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
                filter(visib > 0) %>%
                group_by(dist) %>%
                summarise(varea = sum(area)),
              by = c('dist' = 'dist')) %>%
    ungroup() %>%
    left_join(cr, by = c('dist' = 'dist')) %>%
    mutate(n = ifelse(is.na(n),0,n),
           pr = varea / tarea,
           mi = n/pr,
           s = sum(mi, na.rm = T),
           pmi = mi/s)
  # pmi df
  pmi <- select(int, c('dist', 'pmi'))

  # dwp
  dwp <- vr %>%
    st_drop_geometry() %>%
    group_by(ag, dist) %>%
    summarise(area = sum(area)) %>%
    left_join(
      rings %>%
        st_drop_geometry() %>%
        filter(visib > 0)  %>%
        group_by(ag, dist) %>%
        summarise(area = sum(area)),
      by = c('ag' = 'ag', 'dist' = 'dist')
    ) %>%
    left_join(pmi, by = c('dist' = 'dist')) %>%
    mutate(agdwp =  (area.y/area.x) * pmi) %>%
    ungroup() %>% group_by(ag) %>%
    summarise(dwp = sum(agdwp))

  return(dwp)

}
