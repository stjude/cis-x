
argv <- commandArgs(TRUE)

infile <- argv[1]
outfile <- argv[2]

out <- NULL
dat <- read.table(infile,sep="\t",header=T,quote="")

for (i in 1:nrow(dat)) {
	p_corr <- NULL
  covg <- dat[i,7]
	sigma <- 10.8*(1-exp(-1*covg/105))
	ep <- 0.5
	if (dat[i,9] == "cnvloh") {
		ep <- dat[i,6]
	}
	p_binom <- dbinom(seq(0,covg),covg,ep)
	p_norm  <- dnorm(seq(-1000,1000),mean=0,sd=sigma)
	p_conv  <- convolve(p_binom,p_norm,type="open")
	y <- abs(dat[i,11]/(dat[i,11]+dat[i,10]) - ep)
	if (dat[i,11] > covg*ep) {
		p_corr <- sum(p_conv[(1001+dat[i,11]):length(p_conv)])
	}else {
		p_corr <- sum(p_conv[1:(1001+dat[i,11])])
	}
	if (p_corr < 0) {
		p_corr <- 0
	}
	out <- rbind(out,c(p_corr,y))
}
colnames(out) <- c("pvalue","delta.abs")
out <- cbind(dat,out)

write.table(out,file=outfile,sep="\t",quote=F,row.names=F)
