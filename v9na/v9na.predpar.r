library(Hmisc);
source("graph-func.r");
source("minticks.r");

file.ppc <- paste("./output/",ver,".pred",".rda",sep="");
file.pdf <- paste("./output/",ver,".graph",".pdf",sep="");
file.eps <- function(name) paste("./output/eps/parameters/",name,".eps",sep="");

load(file.ppc); # predpar
# parnum: use y0=1; y1=2; t1=3; alpha=4; shape=5
par.pred <- function(parnum,k.test){
  if(parnum==2){
    par1 <- exp(predpar[k.test,1,]);
    par2 <- exp(predpar[k.test,parnum,]);
    return(par1+par2);
  }
  par <- exp(predpar[k.test,parnum,]);
  if(parnum==5) return(par+1);
  return(par);
}

for(k.test in 1:ntest){
  setEPS();
  postscript(file.eps(paste("y0",ab.nm[k.test,1],ab.nm[k.test,2],sep="")),
             width=4,height=4);
  par(mar=c(4,4,0.5,0)+0.1);
  xlm <- c(0,0); ylm <- c(0,0);
  dns <- density(log10(par.pred(1,k.test)));
  xlm <- c(min(xlm[1],quantile(dns$x,0.2)),max(xlm[2],quantile(dns$x,0.8)));
  ylm <- c(ylm[1],max(ylm[2],max(dns$y)));
  xlm <- c(0,3);
  plot(c(0,0),col="white",xlab="",xlim=xlm,ylim=ylm,main="",xaxt="n",ylab="dens");
  lines(density(log10(par.pred(1,k.test))));
  mtext(expression("y"[0]~"(IU/ml)"),side=1,line=3,cex=1.5);
  ticks.log(1);
  dev.off();

  setEPS();
  postscript(file.eps(paste("y1",ab.nm[k.test,1],ab.nm[k.test,2],sep="")),
             width=4,height=4);
  par(mar=c(4,4,0.5,0)+0.1);
  xlm <- c(0,0); ylm <- c(0,0);
  dns <- density(log10(par.pred(2,k.test)));
  xlm <- c(min(xlm[1],quantile(dns$x,0.2)),max(xlm[2],quantile(dns$x,0.8)));
  ylm <- c(ylm[1],max(ylm[2],max(dns$y)));
  xlm <- c(-1,4);
  plot(c(0,0),col="white",xlab="",xlim=xlm,ylim=ylm,main="",xaxt="n",ylab="dens");
  lines(density(log10(par.pred(2,k.test))));
  mtext(expression("y"[1]~"(IU/ml)"),side=1,line=3,cex=1.5);
  # axis(side=1,at=tickpos,labels=ticklab);
  ticks.log(1);
  dev.off();

  setEPS();
  postscript(file.eps(paste("t1",ab.nm[k.test,1],ab.nm[k.test,2],sep="")),
             width=4,height=4);
  par(mar=c(4,4,0.5,0)+0.1);
  xlm <- c(0,0); ylm <- c(0,0);
  dns <- density(log10(par.pred(3,k.test)));
  xlm <- c(min(xlm[1],quantile(dns$x,0.2)),max(xlm[2],quantile(dns$x,0.8)));
  ylm <- c(ylm[1],max(ylm[2],max(dns$y)));
  xlm <- c(0,2);
  plot(c(0,0),col="white",xlab="",xlim=xlm,ylim=ylm,main="",xaxt="n",ylab="dens");
  lines(density(log10(par.pred(3,k.test))));
  mtext(expression("t"[1]~"(days)"),side=1,line=3,cex=1.5);
  ticks.log(1);
  dev.off();

  setEPS();
  postscript(file.eps(paste("alpha",ab.nm[k.test,1],ab.nm[k.test,2],sep="")),
             width=4,height=4);
  par(mar=c(4,4,0.5,0)+0.1);
  xlm <- c(0,0); ylm <- c(0,0);
  dns <- density(log10(par.pred(4,k.test)));
  xlm <- c(min(xlm[1],quantile(dns$x,0.2)),max(xlm[2],quantile(dns$x,0.8)));
  ylm <- c(ylm[1],max(ylm[2],max(dns$y)));
  xlm <- c(-5,-1);
  plot(c(0,0),col="white",xlab="",xlim=xlm,ylim=ylm,main="",xaxt="n",ylab="dens");
  lines(density(log10(par.pred(4,k.test))));
  mtext(expression(alpha~"(1/days)"),side=1,line=3,cex=1.5);
  # axis(side=1,at=tickpos,labels=ticklab);
  ticks.log(1);
  dev.off();

  setEPS();
  postscript(file.eps(paste("r",ab.nm[k.test,1],ab.nm[k.test,2],sep="")),
             width=4,height=4);
  par(mar=c(4,4,0.5,0)+0.1);
  xlm <- c(0,0); ylm <- c(0,0);
  dns <- density(log10(par.pred(5,k.test)));
  xlm <- c(min(xlm[1],quantile(dns$x,0.2)),max(xlm[2],quantile(dns$x,0.8)));
  ylm <- c(ylm[1],max(ylm[2],max(dns$y)));
  xlm <- c(0,1);
  plot(c(0,0),col="white",xlab="",xlim=xlm,ylim=ylm,main="",xaxt="n",ylab="dens");
  lines(density(log10(par.pred(5,k.test))));
  mtext("r",side=1,line=3,cex=1.5);
  ticks.log(1);
  # axis(side=1,at=tickpos,labels=ticklab);
  dev.off();
}
