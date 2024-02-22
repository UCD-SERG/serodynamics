require("boot")

ticks.lin <- function(ax,n.major,mintick,maxtick,...){
  lims <- par("usr") # get coordinates of graphics interface
  if(ax %in%c(1,3)) lims <- lims[1:2] else lims <- lims[3:4] # bottom,top,left,right?
  if(missing(n.major)) n.major <- 9
  major.ticks <- pretty(lims,n.major) # choose pretty (major) breakpoints
  if(missing(mintick)) mintick <- min(major.ticks) # lowest tick point
  if(missing(maxtick)) maxtick <- max(major.ticks) # highest tick point
  major.ticks <- major.ticks[major.ticks >= mintick & major.ticks <= maxtick]
  if(n.major>1) {
    labels <- sapply(major.ticks,function(i)
              as.expression(bquote(.(i))))
  } else {
  	labels <- FALSE
  }
  axis(ax,at=major.ticks,labels=labels,...) # show major ticks
  if(n.major<10) {
    n.minor <- 11 # include first and last...
    minpos <- pretty(major.ticks[1:2],n.minor)-major.ticks[1]
    minpos <- minpos[-c(1,n.minor)] # remove unwanted elements
    minor.ticks = c(outer(minpos,major.ticks,`+`)) # calculate positions
    minor.ticks <- minor.ticks[minor.ticks > mintick & minor.ticks < maxtick]
    if(n.major>1) {
      labels <- FALSE
    } else {
      labels <- sapply(minor.ticks,function(i)
                as.expression(bquote(.(i))))
    }	
    axis(ax,at=minor.ticks,tcl=par("tcl")*0.5,labels=labels,...) # show minor ticks
  }
}

ticks.log <- function(ax,n.major,mintick,maxtick,...){
  lims <- par("usr") # get coordinates of graphics interface
  if(ax %in%c(1,3)) lims <- lims[1:2] else lims <- lims[3:4] # bottom,top,left,right?
  if(missing(n.major)) n.major <- round(lims[2]-lims[1])
  major.ticks <- pretty(lims,n.major) # choose pretty (major) breakpoints
  if(missing(mintick)) mintick <- min(major.ticks) # lowest tick point
  if(missing(maxtick)) maxtick <- max(major.ticks) # highest tick point
  major.ticks <- major.ticks[major.ticks >= mintick & major.ticks <= maxtick]
  if(n.major>1) {
    labels <- sapply(major.ticks,function(i)
              as.expression(bquote(10^ .(i))))
  } else {
  	labels <- FALSE
  }
  axis(ax,at=major.ticks,labels=labels,...) # show major ticks
  if(n.major<10) {
    n.minor <- 11 # include first and last...
    minpos <- c(outer(log10(pretty(c(1,10),n.minor)),seq(major.ticks[1],major.ticks[2]),`+`))-major.ticks[1]
    minpos <- minpos[-c(1,n.minor)] # remove unwanted elements
    minor.ticks = c(outer(minpos,major.ticks,`+`)) # calculate positions
    minor.ticks <- minor.ticks[minor.ticks > mintick & minor.ticks < maxtick]
    if(n.major>1) {
      labels <- FALSE
    } else {
      labels <- sapply(minor.ticks,function(i)
                as.expression(bquote(.(10^i))))
    }
    axis(ax,at=minor.ticks,tcl=par("tcl")*0.5,labels=labels,...) # show minor ticks
  }
}

ticks.logit <- function(ax,n.major,mintick,maxtick,...){
  lims <- par("usr") # get coordinates of graphics interface
  if(ax %in%c(1,3)) lims <- lims[1:2] else lims <- lims[3:4] # bottom,top,left,right?
  major.templ <- c(10^(-20:-2),(1:9)/10,c(0.99,0.9999,0.999999))
  minor.templ <- c(10^c(outer(log10(2:9),(-20:-1),`+`)),
                   c(0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,
                     0.991,0.992,0.993,0.994,0.995,0.996,0.997,0.998,0.999,
                     0.9991,0.9992,0.9993,0.9994,0.9995,0.9996,0.9997,0.9998,
                     0.99991,0.99992,0.99993,0.99994,0.99995,0.99996,0.99997,0.99998,0.99999,
                     0.999991,0.999992,0.999993,0.999994,0.999995,0.999996,0.999997,0.999998,0.999999))
  majorpos <- logit(major.templ)
  if(missing(mintick)) mintick <- lims[1] # lowest tick point
  if(missing(maxtick)) maxtick <- lims[2] # highest tick point
  major.ticks <- majorpos[majorpos >= mintick & majorpos <= maxtick]
  if(missing(n.major)) n.major <- length(major.ticks)
  if(n.major>10) major.ticks <- major.ticks[major.ticks <= logit(0.1) | major.ticks >= logit(0.9)]
  labels <-sapply(major.ticks,function(x)
    if(x<logit(0.01)) {
           as.expression(bquote(10^ .(log10(inv.logit(x)))))
    } else {
           as.expression(bquote(.(inv.logit(x))))
    })
  axis(ax,at=major.ticks,labels=labels,...) # show major ticks
  minorpos <- logit(minor.templ)
  minor.ticks <- minorpos[minorpos >= lims[1] & minorpos <= lims[2]]
  axis(ax,at=minor.ticks,tcl=par("tcl")*0.5,labels=FALSE,...) # show minor ticks
}

