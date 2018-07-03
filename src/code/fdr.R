
library(multtest)

argv <- commandArgs(TRUE)

infile <- argv[1]
outfile <- argv[2]

dat <- read.table(infile,sep="\t",header=T,quote="",stringsAsFactor=F)

out <- NULL
pval <- NULL
ai <- NULL

for (i in 1:nrow(dat)) {
	x <- as.numeric(unlist(strsplit(as.character(dat[i,13]),",",perl=T)))
	y <- as.numeric(unlist(strsplit(as.character(dat[i,15]),",",perl=T)))
	x.geom <- exp(sum(log(x))/length(x))
	y.m <- mean(y)
	out <- rbind(out, c(x.geom,y.m))
}

colnames(out) <- c("comb.pval","mean.delta")
rownames(out) <- dat[,1]

if (nrow(dat) == 1) {
    out <- cbind(out,out[,1],out[,1],out[,1])
    colnames(out) <- c(colnames(out)[1:2],c("rawp","Bonferroni","ABH"))
    out <- cbind(dat,out)
}else {
    raw.p <- out[,1]
    adj.p <- mt.rawp2adjp(raw.p,c("Bonferroni","ABH"))$adj
    rownames(adj.p) <- names(raw.p[order(raw.p)])
    out <- cbind(out,adj.p[rownames(out),])
    out <- cbind(dat,out)
}

write.table(out,file=outfile,sep="\t",quote=F,row.names=F)
