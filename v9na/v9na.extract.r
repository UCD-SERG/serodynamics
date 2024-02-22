library(coda);

file.pmc <- paste("./output/",ver,".mcmc",".rda",sep="");
file.ppc <- paste("./output/",ver,".pred",".rda",sep="");

mcmc.mat <- as.matrix(as.mcmc.list(jags.post));
nmc <- nrow(mcmc.mat);
pred.subj <- nsubj+1;

extr.var <- function(nam,index){
  var.mc <- c();
  varname <- paste(nam,"[",sep="");
  if(length(index)==1) varname <- paste(varname,index,"]",sep="");
  if(any(is.na(index))) varname <- nam;
  if(length(index)>1){
    for(k.index in 1:(length(index)-1)){
      varname <- paste(varname,index[k.index],",",sep="");
    }
    varname <- paste(varname,index[length(index)],"]",sep="");
  }
  var.mc <- mcmc.mat[,which(colnames(mcmc.mat)==varname)];
  return(var.mc);
}

# parnum: use y0=1; y1=2; t1=3; alpha=4; shape=5
par.mc <- function(parnum,k.subj,k.test){
  if(parnum==2){
    par1 <- exp(extr.var("par",c(k.subj,k.test,1)));
    par2 <- exp(extr.var("par",c(k.subj,k.test,parnum)));
    return(par1+par2);
  }
  par <- exp(extr.var("par",c(k.subj,k.test,parnum)));
  if(parnum==5) return(par+1);
  return(par);
}

predpar <- array(NA,dim=c(ntest,ndim,nmc));
for(k.test in 1:ntest){
  for(pnum in 1:ndim){
    predpar[k.test,pnum,] <- extr.var("par",c(pred.subj,k.test,pnum));
  }
}

# save(mcmc.mat,file=file.pmc,ascii=TRUE);
save(predpar,file=file.ppc,ascii=TRUE);
