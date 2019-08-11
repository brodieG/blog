

# Alternatively we could get the actual coordinates from the grobs
# * pp <- ggplot_gtable(ggplot_build(p))
# * Look for grobs with right dimension
# * Seems a bit of a pita b/c we have to figure out nesting, etc.
# For our simple case, much easier to just compute directly on the image.

png <- png::readPNG('~/Downloads/colsums2/img-012.png') * 255
RNGversion("3.5.2"); set.seed(42)
set.seed(1)
gn <- 10
g2 <- sample(seq_len(gn), 95, replace=TRUE)
x <- runif(length(g2))
xo <- x[order(g2)]

# First find out what cells have gray colors

gray <- which(
  rowSums(
    abs(png[,,1:3] - c(rowSums(png[,,1:3], dims=2)) / 3), dims=2
  ) < 0.00001,
  arr.ind=TRUE
)
# And which color is the dominant gray; this is the panel background

gray.vals <- table(png[cbind(gray, 1L)])
panel.col <- as.numeric(names(gray.vals[which.max(gray.vals)]))

# Find the boundaries of the panel

pnl.pix <- rowSums(abs(png[,,1:3] - panel.col), dims=2) == 0
pnl.pix.w <- which(pnl.pix, arr.ind=TRUE)
stopifnot(nrow(pnl.pix.w) == gray.vals[which.max(gray.vals)])

# We know roughly that 1/8th of the pixels in we're dealing with the map
# portion KEEP IN MIND Y/X flipped to image, below we use the matrix X/Y

pnl.rle.y <- rle(pnl.pix[nrow(pnl.pix)/4, ])
map.pix.y <- cumsum(pnl.rle.y[['lengths']][1:3])[c(2,3)]
map.pix.y # yup, seems reasonabl

pnl.rle.x <- rle(pnl.pix[, map.pix.y[1] + 2])
map.pix.x <- cumsum(pnl.rle.x[['lengths']][1:3])[c(2,3)]
map.pix.x # yup, seems reasonabl

# figure out the group sum location based on the first locations

pnl.rle.y2 <- rle(pnl.pix[map.pix.x[1] + 2, ])
map.pix.y2 <- cumsum(pnl.rle.y2[['lengths']][1:5])[c(4,5)]
map.pix.y2

pnl.rle.x2 <- rle(pnl.pix[, mean(map.pix.y2)])
map.pix.x2 <- cumsum(pnl.rle.x2[['lengths']][1:3])[c(2,3)]
map.pix.x2 # yup, seems reasonabl

# Generate the coordinates for the tiles, the last coordinate is
# purposefully out of bounds

make_elev <- function(pix.x, pix.y, nrow, len, elev, val) {
  cols <- ceiling(len/nrow)
  ys <- round(seq(from=1, to=diff(pix.y) + 2L, length.out=cols + 1L)) +
    pix.y[1] - 1L
  xs <- round(seq(from=1, to=diff(pix.x) + 2L, length.out=nrow + 1L)) +
    pix.x[1] - 1L

  ymins <- head(ys, -1)
  ymaxs <- tail(ys, -1) - 1
  xmins <- head(xs, -1)
  xmaxs <- tail(xs, -1) - 1

  # Now make the tiles (first 95)

  tiles <- data.frame(
    ymin=rep(ymins, each=nrow), ymax=rep(ymaxs, each=nrow),
    xmin=rep(xmins, nrow), xmax=rep(xmaxs, nrow)
  )[seq_len(len),]

  for(i in seq_len(nrow(tiles))) {
    xins <- seq(from=tiles[i,'xmin'], to=tiles[i,'xmax'], by=1)
    yins <- seq(from=tiles[i,'ymin'], to=tiles[i,'ymax'], by=1)
    elev[xins, yins] <- val[i]
  }
  elev
}
elev.start <- elev.end <- array(0, dim=dim(png)[1:2])

# Start elevation

elev.start <- make_elev(map.pix.x, map.pix.y, 10, 95, elev.start, x)
elev.end <- make_elev(map.pix.x, map.pix.y, 10, 95, elev.end, xo)
elev.end <- make_elev(
  map.pix.x2, map.pix.y2, 1, 10, elev.end, c(rowsum(xo, go))
)

# With the tiles we can create an elevation map using the original values, there
# are only 95 tiles so we're going to be lazy and do them in a for loop

#
# Use the elevation map to compute shade

# shade <- shadow::ray_shade2(elev * , sunangle=315-90, anglebreaks=seq(30,60,1))

angles <- seq(45, 90, by=5)
deltas <- (-5):5
delta.fac <- seq(1, 0, length.out=length(deltas))

elev <- elev.end
png.root <- '~/Downloads/colsums2/rs-img-%03d.png'
for(i in seq_along(angles)) {
  shade <- rayshader::ray_shade(
    elev * 50, sunangle=-40, lambert=FALSE,
    anglebreaks=angles[i] + (deltas * delta.fac[i]), maxsearch=300
  ) * .8 + .2
  png.fin <- png/255
  png.fin[,,1:3] <- png.fin[,,1:3] * c(shade[,rev(seq_len(ncol(shade)))])
  png::writePNG(png.fin, sprintf(png.root, i))
}

par(mai=numeric(4))


plot(as.raster(png.fin))

dev.new()
par(mai=numeric(4))
plot(as.raster(elev))

png.fin.u <- rowMeans(png.fin[,,1:3], dims=2)

xx <- shadow::render_elevation(elev, png.fin.u, c(20,20,20))

mesh.tri <- mesh
lim <- 120000
off <- 0
idx <- seq(lim * 4) + off * 4
x <- do.call(rbind, c(mesh.tri[,'x'], list(NA)))
y <- do.call(rbind, c(mesh.tri[,'y'], list(NA)))
texture <- gray((Reduce('+', mesh.tri[,'t'])/nrow(mesh.tri)))
plot_new(x, y)
polygon(rescale(x), rescale(y), col=texture, border=texture)


# png.fin <- array(0, dim(png))
png.fin[,,4] <- elev
png::writePNG(png.fin, "~/Downloads/elev.png")



ggplot(tiles) + geom_rect(aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax))