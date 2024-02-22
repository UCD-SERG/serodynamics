library(Hmisc);
source("graph-func.r");
source("minticks.r");

file.ppc <- paste("./output/",ver,".pred",".rda",sep="");
file.pdf <- paste("./output/",ver,".graph",".pdf",sep="");
file.eps <- function(name) paste("./output/eps/predicted/",name,".eps",sep="");

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

tx1 <- 10^seq(-1,2.4,0.025);
tx2 <- 10^seq(-1,3,0.025);

ymax <- 6000;

for(k.test in 1:ntest){
  cat(k.test," ");
  setEPS();
  postscript(file.eps(paste("log-",ab.nm[k.test,1],"-",ab.nm[k.test,2],sep="")),
             width=5,height=5);
  par(mar=c(4,4,0.5,0)+0.1);
  plot(c(0,0),xlim=c(min(tx2),max(tx2)),ylim=c(0,log10(ymax)),yaxt="n",
       col="white",xlab="Time (days)",
       ylab=paste(ab.nm[k.test,1],ab.nm[k.test,2]," (U/mL)",sep=""));
  for(k.subj in 1:nsubj){
    lines(smpl.t[k.subj,],log10(smpl.y[k.subj,,k.test]),col="gray");
    points(smpl.t[k.subj,],log10(smpl.y[k.subj,,k.test]),col="gray");
  }
  y0.pred <- par.pred(1,k.test);
  y1.pred <- par.pred(2,k.test);
  t1.pred <- par.pred(3,k.test);
  alpha.pred <- par.pred(4,k.test);
  shape.pred <- par.pred(5,k.test);
  sxmed <-  serocourse(tx2,0.500,y0.pred,y1.pred,t1.pred,
                       alpha.pred,shape.pred);
  sxlow <-  serocourse(tx2,0.025,y0.pred,y1.pred,t1.pred,
                       alpha.pred,shape.pred);
  sxhigh <-  serocourse(tx2,0.975,y0.pred,y1.pred,t1.pred,
                        alpha.pred,shape.pred);
  lines(tx2,log10(sxhigh),"l");
  lines(tx2,log10(sxlow),"l");
  lines(tx2,log10(sxmed),"l");
  axis(side=2,at=tickpos,labels=ticklab);
  dev.off();
}
cat("\n");
