
argvs <- commandArgs(TRUE)

infile <- paste(argvs[1],"cis-X.refexp.step2.collect.filtered.txt",sep="/")
outfile <- paste(argvs[1],"cis-X.refexp.step2.collect.filtered.bi.samples.cleared.txt",sep="/")
dat.raw <- read.table(infile,sep="\t",header=T,row.names=1,quote="",stringsAsFactors=F)
dat <- dat.raw

out <- NULL
for (i in 1:nrow(dat)) {
	s.i <- NULL
	s.clear <- NULL
	f.i <- NULL
	f.clear <- NULL
	s.count <- NULL
	trim <- 0
	tot.i <- dat[i,2]+dat[i,5]
	if (dat[i,5]>=10) {
		bi.i <- unlist(strsplit(dat[i,6],",",perl=T))
		bi.fpkm <- as.numeric(unlist(strsplit(dat[i,7],",",perl=T)))
		names(bi.fpkm) <- bi.i
		y.i <- as.numeric(log10(bi.fpkm+0.1))
		if (length(unique(bi.fpkm)) == 1) {
			s.i <- ""
			s.clear <- ""
			f.i <- ""
			f.clear <- ""
			s.count <- ""
		}else if (length(y.i[y.i<0])/length(y.i) == 1) {
			s.i <- ""
			s.clear <- ""
			f.i <- ""
			f.clear <- ""
			s.count <- ""
		}else {
			for (j in 1:length(bi.i)){
				x.j <- y.i[j]
				y.j <- y.i[-j]
				t.j <- (x.j-mean(y.j))/((1+(length(y.j)-2)^-1)*(sd(y.j)^2))^0.5
				p.j <- pt(t.j,length(y.j)-2,lower.tail=F)
				if (p.j < 0.05) {
					s.i <- c(s.i,bi.i[j])
					f.i <- c(f.i,as.numeric(bi.fpkm)[j])
					trim <- 1
				}else {
					s.clear <- c(s.clear,bi.i[j])
					f.clear <- c(f.clear,as.numeric(bi.fpkm)[j])
				}
			}
			if (trim == 1) {
				s.count <- length(s.clear)
			}else {
				s.count <- ""
			}
		}
	}else {
		s.i <- ""
		s.clear <- ""
		f.i <- ""
		f.clear <- ""
		s.count <- ""
	}
	s.i <- paste(s.i,collapse=",")
	f.i <- paste(f.i,collapse=",")
	s.clear <- paste(s.clear,collapse=",")
	f.clear <- paste(f.clear,collapse=",")
	out <- rbind(out,c(tot.i,trim,s.count,s.clear,f.clear,s.i,f.i))
}
colnames(out) <- c("num.total.samples","trim","num.bi.samples.cleared","bi.samples.cleared","bi.fpkm.cleared","bi.samples.excluded","bi.fpkm.excluded")
out.r <- cbind(rownames(dat),dat,out)
colnames(out.r)[1] <- "Gene"
write.table(out.r,file=outfile,sep="\t",row.names=F,quote=F)
