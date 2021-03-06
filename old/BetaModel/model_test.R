library(rstan)
library(MASS) # For mvrnorm

source("../Shared.R")

# make stan parallel 
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores()) 

options(width=Sys.getenv("COLUMNS"))  # fix the number of columns

modelcode <- paste(readLines('beta_model.stan'), collapse = '\n')

N_CELLS <- 100
DATA_PER_CELL <- 200

set.seed(100)

make_data <- function(betas,N_CELLS,DATA_PER_CELL, M){
  d <- NULL
  obs <- NULL
  sigma <- array(0,dim=c(N_CELLS,2,2))
  for(r in 1:nrow(betas)) {
    b <- betas[r,]
    
    m <- matrix(runif(DATA_PER_CELL*2), ncol=2)
    
    err <- rnorm(DATA_PER_CELL, 0.0, 0.20)
    d <- data.frame(cell=r, x1=m[,1], x2=m[,2], y= m%*%b+err)
    fits <- lm(y ~ x1 + x2, data = d);
    obs <- rbind(obs,fits$coefficients[2:3]);
    sigma[r,,] <- vcov(fits)[2:3,2:3]; #covariance matrix for the coefficients
  }
  
  # Construct the data to send
  data <- list(N_CELLS=N_CELLS, 
               M=M, 
               dim=2,
               alpha_cov_mix=array(rep(1,M),dim=M), # dirichlet prior. Need to declare as array to work with M=1
               alpha_noise_mix=c(1,1), # Set a uniform prior for signal vs noise
               x = obs,
               sigma = sigma
  )      
  return(data);
}

M = 2;

# Make up regression data

# 1 cov with positively correlated variables
betas_1poscov <- mvrnorm(n=N_CELLS, mu=c(0,0), Sigma=matrix(c(1,1.5, 1.5,3), nrow=2))
# 2 covs, orthogonal to each other
betas_2orthcov <- rbind(mvrnorm(n=N_CELLS/2, mu=c(0,0), Sigma=matrix(c(1,1.5, 1.5,3), nrow=2)),mvrnorm(n=N_CELLS/2, mu=c(0,0), Sigma=matrix(c(1,-1.5, -1.5,3), nrow=2)))
# 1 cov + noise (half and half)
betas_1poscov_noise <- rbind(mvrnorm(n=N_CELLS/2, mu=c(0,0), Sigma=matrix(c(1,1.5, 1.5,3), nrow=2)),mvrnorm(n=N_CELLS/2, mu=c(0,0), Sigma=matrix(c(0,0,0,0), nrow=2)))
# 1 circular cov
betas_1circcov <- mvrnorm(n=N_CELLS, mu=c(0,0), Sigma=matrix(c(3,0,0,3), nrow=2))
# 2 orthogonal covs + noise (half noise)
betas_2orthcov_noise <- rbind(mvrnorm(n=N_CELLS/4, mu=c(0,0), Sigma=matrix(c(1,1.5, 1.5,3), nrow=2)),mvrnorm(n=N_CELLS/4, mu=c(0,0), Sigma=matrix(c(1,-1.5, -1.5,3), nrow=2)),mvrnorm(n=N_CELLS/2, mu=c(0,0), Sigma=matrix(c(0,0,0,0), nrow=2)))        

data= make_data(betas_1poscov,N_CELLS,DATA_PER_CELL, 1);
test <- stan(model_code=modelcode, data=data, iter=10, chains=1);

data= make_data(betas_1poscov,N_CELLS,DATA_PER_CELL, 1);
fit1cov_1poscov <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_1poscov,N_CELLS,DATA_PER_CELL, 2);
fit2cov_1poscov <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_1poscov,N_CELLS,DATA_PER_CELL, 3);
fit3cov_1poscov <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_2orthcov,N_CELLS,DATA_PER_CELL, 1);
fit1cov_2orthcov <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_2orthcov,N_CELLS,DATA_PER_CELL, 2);
fit2cov_2orthcov <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_2orthcov,N_CELLS,DATA_PER_CELL, 3);
fit3cov_2orthcov <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_1poscov_noise,N_CELLS,DATA_PER_CELL, 1);
fit1cov_1poscov_noise <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_1poscov_noise,N_CELLS,DATA_PER_CELL, 2);
fit2cov_1poscov_noise <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_1poscov_noise,N_CELLS,DATA_PER_CELL, 3);
fit3cov_1poscov_noise <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_2orthcov_noise,N_CELLS,DATA_PER_CELL, 1);
fit1cov_2orthcov_noise <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_2orthcov_noise,N_CELLS,DATA_PER_CELL, 2);
fit2cov_2orthcov_noise <- stan(model_code=modelcode, data=data, iter=10000, chains=5);

data= make_data(betas_2orthcov_noise,N_CELLS,DATA_PER_CELL, 3);
fit3cov_2orthcov_noise <- stan(model_code=modelcode, data=data, iter=10000, chains=5);
