% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_visib.R
\docType{data}
\name{visib}
\alias{visib}
\title{layer with turbine visibility mapped}
\format{A shapefile with 4 columns
\describe{
  \item{ag}{unique turbine id}
  \item{visib}{visibility class (0 to 6)}
}}
\source{
Candeeiros WF monitoring
}
\usage{
visib
}
\description{
layer with turbine visibility mapped
}
\examples{
\dontrun{
library(genestdwp)
library(sf)
library(ggplot2)
summary(visib)
ggplot() +
geom_sf(aes(fill = as.numeric(area)),
       size = .5, data = visib) +
theme_void()
}
}
\author{
Paulo E. Cardoso
}
\keyword{datasets}
