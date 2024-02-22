library(Hmisc);
source("graph-func.r");
source("minticks.r");

file.pmc <- paste("./output/",ver,".mcmc",".rda",sep="");
file.pdf <- paste("./output/",ver,".graph",".pdf",sep="");
file.eps <- function(name) paste("./output/eps/residuals/",name,".eps",sep="");

# load(file.pmc)

for(k.test in 1:ntest){
  cat(k.test," ");
  residq <- numeric(0);
  k <- 1;
  for(k.subj in 1:(nsubj)){
    for(k.obs in 1:nsmpl[k.subj]){
      obs <- log10(smpl.y[k.subj,k.obs,k.test]);
      pred <- log10(qsero(smpl.t[k.subj,k.obs],c(0.025,0.5,0.975),
                          par.mc(1,k.subj,k.test),
                          par.mc(2,k.subj,k.test),
                          par.mc(3,k.subj,k.test),
                          par.mc(4,k.subj,k.test),
                          par.mc(5,k.subj,k.test)));
      residq <- cbind(residq,c(k,pred-obs,smpl.t[k.subj,k.obs]));
      k <- k+1;
    }
  }
  setEPS();
  postscript(file.eps(paste("resid",ab.nm[k.test,1],ab.nm[k.test,2],sep="")),
             width=5,height=3);
  par(mar=c(4,4,0.5,0)+0.1);
  errbar(x=residq[1,],y=residq[3,],yplus=residq[4,],yminus=residq[2,],
         add=FALSE, ylim=c(-2,2),
         xlab="observation #",ylab="residual (log)",errbar.col="black");
  dev.off();
}
cat("\n");
