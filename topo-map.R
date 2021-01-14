library(sf)
library(ggplot2)
topo_shape <- sf::st_read("topo-shp/GAW2535014350.shp")
sf::st_geometry_type(topo_shape)
sf::st_crs(topo_shape)
ggplot2::ggplot() + 
  geom_sf(data = topo_shape, aes(color=Contour, fill=Contour)) +
  scale_color_continuous(low='#006400', high='#7CFC00') +
  scale_fill_continuous(low='#006400', high='#7CFC00') +
  ggtitle("AOI Boundary Plot") + 
  coord_sf() 
  
nrow(topo_shape)
topo_shape['Countour',]
