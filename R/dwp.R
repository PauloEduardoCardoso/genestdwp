#' DWP
#' @description The \code{dwp} function will create the table with Density Weighted
#' Probability required to run \code{genest}.
#'
#' @param vr a shapefile describing the visibility for each turbine at each ring.
#' Ideally should be obtained with \code{virings}.
#'
#' @param pt a shapefile with carcass positions with an unique ID for each one.
#'
#' @return a data.frame with dwp for each turbine at each ring distance.
#'
#' @details DWP will be obtained for a single group. Ensure that pt is a vector with
#' the group size you are interested in.
#'
#' @author Paulo E. Cardoso
#'
#' @importFrom sf st_join
#' @importFrom sf st_crs
#' @importFrom sf st_buffer
#' @importFrom sf st_cast
#' @importFrom sf st_difference
#' @importFrom sf st_intersection
#' @importFrom sf st_intersects
#' @importFrom sf st_drop_geometry
#' @importFrom sf st_nearest_feature
#' @importFrom dplyr group_by
#' @importFrom dplyr left_join
#' @importFrom dplyr mutate
#' @importFrom dplyr summarise
#' @importFrom dplyr filter
#' @importFrom dplyr select
#' @importFrom dplyr tally
#' @importFrom dplyr n
#' @importFrom dplyr ungroup
#' @importFrom purrr map
#' @export
#' @examples
#' \dontrun{
#' require(genestdwp)
#' require(units)
#' # Vector of distances
#' dist = c(10, 20, 30, 40, 50)
#'
#' # Spatial join among visibility map and rings
#' rings <- viring(x = visib, d = dist)
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
#' }
dwp <- function(vr, pt){

  #Check projections
  if(any(is.na(st_crs(vr)),is.na(st_crs(pt)))){
    stop('Both layers must have their crs defined')
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
  vr$dist <- as.numeric(vr$dist)
  vr$area <- as.numeric(vr$area)
  cr <- pt[ ,-1] %>%
    st_join(select(vr, ag, dist, visib), join = st_intersects) %>%
    filter(!is.na(visib))

  if(nrow(filter(cr, visib == 0)) != 0){
    print('Attention!')
    print(st_drop_geometry(filter(select(cr, ag, visib), visib == 0)))
    print(paste('Found n =',
                  nrow(filter(cr, visib == 0)),
                  'Found carcasses on visibility class = 0. Assuming value of nearest visible area'))
    cr <- cr %>%
      st_join(filter(vr, visib != 0), join = st_nearest_feature)
    cr <- select(cr, tamanho, ag = ag.x, dist = dist.y, visib = visib.y)
  }
  cr <- cr %>%
    st_drop_geometry() %>%
    group_by(dist) %>%
    tally()
  # Obtaining pmi
  int <- vr %>%
    st_drop_geometry() %>%
    filter(dist <= 50) %>%
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
    mutate(no = ifelse(is.na(n), 0 , n),
           pr = varea / tarea,
           mi = no/pr,
           s = sum(mi, na.rm = T),
           pmi = mi/s)
  # pmi df
  pmi <- select(int, c(dist, pmi))
  # dwp
  dwp <- vr %>%
    st_drop_geometry() %>%
    group_by(ag, dist = dist) %>%
    summarise(area = sum(area)) %>%
    left_join(
      vr %>%
        st_drop_geometry() %>%
        filter(visib > 0)  %>%
        group_by(ag, dist = dist) %>%
        summarise(area = sum(as.numeric(area))),
      by = c('ag' = 'ag', 'dist' = 'dist')
    ) %>% ungroup() %>%
    left_join(pmi, by = c('dist' = 'dist')) %>%
    mutate(agdwp =  (area.y/area.x) * pmi) %>%
    group_by(ag) %>%
    summarise(dwp = sum(agdwp))

  return(dwp)

}
