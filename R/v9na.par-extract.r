ver <- "v9na";


basepath <- "~/Dropbox/DataAnalysis/EntericFever/EF_longitudinal/jointmod/v9na/"
source(paste(basepath,ver,".data",".r",sep=""));
file.ppc <- paste(basepath,"output/",ver,".pred",".rda",sep="");
filepar <- function(k.test)
  return(paste("longpar-",
               ab.nm[k.test,1],"-",ab.nm[k.test,2],".rda",sep=""));
load(file.ppc); # predpar

# Generate longitudinal parameter sample for the serocalculator
# parnum: use y0=par[1]; y1=par[2]; t1=par[3]; alpha=par[4]; shape=par[5]
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

ltpar <- function(k.test){
  y0.mc       <- par.pred(1,k.test);
  y1.mc       <- par.pred(2,k.test);
  t1.mc       <- par.pred(3,k.test);
  alpha.mc    <- par.pred(4,k.test);
  shape.mc    <- par.pred(5,k.test);
  return(data.frame("y1"=y1.mc,"alpha"=alpha.mc,"r"=shape.mc,
              "y0"=y0.mc,"t1"=t1.mc));
}

# Generate longitudinal parameter sample for the simulation model
# parnum: use y0=par[1]; b0=par[2]; mu0=par[3]; mu1=par[4]; c1=par[5];
# alpha=par[6]; shape=par[7] (dmu = mu1 - mu0; b0 = 1)
mu1fn   <- function(y0,y1,t1) log(y1/y0)/t1;
mu0fn   <- function(beta,y0,y1,t1) mu1fn(y0,y1,t1)*exp(beta)/(1+exp(beta));
dmufn   <- function(beta,y0,y1,t1) mu1fn(y0,y1,t1)/(1+exp(beta));
t1fn    <- function(beta,y0,y1,t1,c1)
  log(1+dmufn(beta,y0,y1,t1)/(c1*y0))/dmufn(beta,y0,y1,t1);
y1fn    <- function(beta,y0,y1,t1,c1)
  y0*(1+dmufn(beta,y0,y1,t1)/(c1*y0))^(1+exp(beta))
objfnt1 <- function(par,y0,y1,t1) (t1-t1fn(par[1],y0,y1,t1,exp(par[2])))^2;
# the longitudinal model estimates observables: y0, y1, t1, alpha, shape
# for the simulation model we need mu0, mu1 and c1 (=c/b0)
# mu1 can be calculated (see above) but mu0 and c1 are not so easy
# the equation for t1 (above) can be used to calculate dmu (= mu1 - mu0)
# and c1. We need a pair (dmu, c1) that minimizes the difference
# (t1 - t1fn(dmu, c1, y0))^2. This is done in the following function
estpart1 <- function(y0,y1,t1){
  # est <- nlm(objfn,c(-1,-12),y0=y0,t1=t1); # print(est$estimate);
  # if(sqrt(est$minimum/t1)>1e0) print(sqrt(est$minimum));# return(NA);
  # return(exp(est$estimate));
  est <- optim(c(-1,-12),objfnt1,y0=y0,y1=y1,t1=t1,method="Nelder-Mead");
  if(sqrt(est$value/t1)>1e-1) print(sqrt(est$value));
  return(c(exp(est$par[1])/(1+exp(est$par[1])),exp(est$par[2])));
}

par.pred.n <- function(parnum,k.test,nmc){
  if(parnum==2){
    par1 <- exp(predpar[k.test,1,nmc]);
    par2 <- exp(predpar[k.test,parnum,nmc]);
    return(par1+par2);
  }
  par <- exp(predpar[k.test,parnum,nmc]);
  if(parnum==5) return(par+1);
  return(par);
}

simpar <- function(age,k.test,nmc){
  y0.mc       <- par.pred.n(1,k.test,nmc);
  b0.mc       <- 1;
  y1.mc       <- par.pred.n(2,k.test,nmc);
  t1.mc       <- par.pred.n(3,k.test,nmc);
  alpha.mc    <- par.pred.n(4,k.test,nmc);
  shape.mc    <- par.pred.n(5,k.test,nmc);
  sp <- estpart1(y0.mc,y1.mc,t1.mc);
  mu1.mc <- mu1fn(y0.mc,y1.mc,t1.mc);
  mu0.mc <- mu0fn(sp[1],y0.mc,y1.mc,t1.mc);
  c1.mc  <- sp[2];
  return(c(y0.mc,b0.mc,mu0.mc,mu1.mc,c1.mc,alpha.mc,shape.mc));
}

