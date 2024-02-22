library(Hmisc);
source("graph-func.r");
source("minticks.r");

epsw <- 4; epsh <- 3.25;

file.ppc <- paste("./output/",ver,".pred",".rda",sep="");
file.pdf <- paste("./output/",ver,".graph",".pdf",sep="");
file.eps <- function(name) paste("./output/eps/wdist/",name,".eps",sep="");

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

wx <- seq(0,0.1,0.001);
logwx <- seq(-5,1.5,0.1);
# qv <- (99:1)/100;
qv <- c(0.505,0.495);

maxdens <- 0;
for(k.test in 1:ntest){
  y1.pred <- par.pred(2,k.test);
  alpha.pred <- par.pred(4,k.test);
  shape.pred <- par.pred(5,k.test);
  logwquan <- wlogdistquan(logwx,qv,y1.pred,alpha.pred,shape.pred);
  maxdens <- max(maxdens,max(logwquan));
  maxdens <- maxdens*1.1;
  setEPS();
  postscript(file.eps(paste("logwdist-",ab.nm[k.test,1],"-",
                            ab.nm[k.test,2],sep="")),
             width=epsw,height=epsh);
  par(mar=c(4,4,0.5,0)+0.1);
  plot(c(0,0),xlim=c(-5,1.5),ylim=c(0,maxdens),col="white",
       xlab="",ylab="dens");
  mtext("log(w)",side=1,line=3,cex=1.5);
  y1.pred <- par.pred(2,k.test);
  alpha.pred <- par.pred(4,k.test);
  shape.pred <- par.pred(5,k.test);
  logwquan <- wlogdistquan(logwx,qv,y1.pred,alpha.pred,shape.pred);
  maxdens <- max(logwquan)*1.25;
  lines(logwx,logwquan[,round(length(qv)/2)],col="black");
  for(k in 1:round(length(qv)/2)) {
      polygon(c(logwx,rev(logwx)),c(logwquan[,k],rev(logwquan[,length(qv)-k])),
              col=gray(sqrt(1-k/50)),border=NA);
  }
  dev.off();
}
