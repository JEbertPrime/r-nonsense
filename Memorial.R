library(lidR)
library(sf)
library(raster)
library(tmap)
library(tmaptools)
library(RColorBrewer)
library(future)
library(rayshader)
library(tidyverse)
library(tiff)
lidR::set_lidr_threads(0)
parks<- sf::st_read('parks/ACC_Parks.shp')
memorial_park <- filter(parks, Park_Name=="Memorial Park")

trails <- sf::st_read('trails/Trails.shp')
trails<-st_combine(trails)
birchmore_trail<- filter(trails, str_detect(TR_NAME, "^Birchmore"))
birchmore_masked<- st_crop(memorial_park, birchmore_trail)
plot(birchmore_trail)
birchmore_trail<- unlist(birchmore_trail)
birchmore_spatial<- as_Spatial(birchmore_trail)
birchmore_extent<-extent(memorial_raster_cropped)
las <- readLAS("lidar/memorial/GAW2530014250.las")
dtm<- grid_terrain(las, res=1, knnidw(k = 5, p = 2))
memorial_raster <- mask(dtm, memorial_park)
memorial_raster_cropped <- crop(memorial_raster, memorial_park)

ortho_imagery_1<-raster::stack("imagery/w2530014250.tif")
ortho_imagery_2<-raster::stack('imagery/w2530014300.tif')
ortho_memorial<-raster::merge(ortho_imagery_1,ortho_imagery_2)

plan(multisession, workers=2L)
ortho_memorial<-mask(ortho_memorial, memorial_park)
ortho_memorial_cropped<-crop(ortho_memorial, memorial_park)
names(ortho_memorial_cropped) = c("r","g","b","alpha")

ortho_r <- rayshader::raster_to_matrix(ortho_memorial_cropped$r)
ortho_g<- rayshader::raster_to_matrix(ortho_memorial_cropped$g)
ortho_b<- rayshader::raster_to_matrix(ortho_memorial_cropped$b)

ortho_array = array(0,dim=c(nrow(ortho_r),ncol(ortho_r),3))
ortho_array[,,1] = ortho_r/255 #Red layer
ortho_array[,,2] = ortho_g/255 #Blue layer
ortho_array[,,3] = ortho_b/255 #Green layer
ortho_array = aperm(ortho_array, c(2,1,3))
plot_map(ortho_array)
plot(memorial_raster_cropped)
elmat<- raster_to_matrix(memorial_raster_cropped)
elmatSmall<- resize_matrix(elmat)
elmat %>%
  sphere_shade(texture = "desert") %>%
  plot_map()
plot_3d(ortho_array, elmat, windowsize = c(1100,900), zscale = 1, shadowdepth = -50,
        zoom=0.5, phi=45,theta=-45,fov=70, background = "#F2E1D0", shadowcolor = "#523E2B")
render_path(clear_previous = TRUE)
render_path(extent=birchmore_extent, lat = birchmore_spatial, heightmap = elmat)
render_water(elmat)
elmat %>%
  sphere_shade()%>%
  add_water(detect_water(elmat), color = "blue") %>%
  plot_3d(ortho_array, windowsize = c(1100,900), zscale = 1, shadowdepth = -50,
          zoom=0.5, phi=45,theta=-45,fov=70, background = "#F2E1D0", shadowcolor = "#523E2B")
rayshader::render_movie('memorial_park_trails')
render_highquality()
