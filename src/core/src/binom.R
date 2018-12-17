
argv <- commandArgs(TRUE)

infile <- argv[1]
outfile <- argv[2]

out <- NULL
dat <- read.table(infile,sep="\t",header=T,quote="")

for (i in 1:nrow(dat)) {
	ep <- 0.5
	if (dat[i,9] == "cnvloh") {
		ep <- dat[i,6]
	}
	x <- binom.test(dat[i,11],dat[i,11]+dat[i,10],ep)
	y <- abs(dat[i,11]/(dat[i,11]+dat[i,10]) - ep)
	out <- rbind(out,c(x$p.value,y))
}
colnames(out) <- c("pvalue","delta.abs")
out <- cbind(dat,out)

write.table(out,file=outfile,sep="\t",quote=F,row.names=F)

