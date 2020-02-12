
argv <- commandArgs(TRUE)

workdir <- argv[1]

infile <- paste(workdir,"/refexp/exp.ref.bi.txt",sep="")
outfile <- paste(workdir,"/raw.tvalue.bicohort.txt",sep="")
dat <- read.table(infile,sep="\t",header=T,row.names=1,quote="",stringsAsFactors=F)
rawt <- NULL

for (i in 1:nrow(dat)) {
  rawt.i <- NULL
  y.in  <- NULL
  y.raw <- NULL
  y.size <- NULL
  y.median <- NULL
  y.in  <- as.numeric(unlist(strsplit(dat[i,3],",",perl=T)))
  y.raw <- log10(as.numeric(unlist(strsplit(dat[i,3],",",perl=T)))+0.1)
  y.median <- median(y.in)
  y.size <- length(y.in)

  if (y.size >= 20 && y.median >= 1) {
    for (j in 1:length(y.raw)) {
      y.white <- y.raw[-j]
      x.i <- y.raw[j]
      t.white <- (x.i-mean(y.white))/((1+(length(y.white)-2)^-1)*(sd(y.white)^2))^0.5
      p.white <- pt(t.white,length(y.white)-2,lower.tail=F)
      if (j == 1) {
        rawt.i <- t.white
      }else {
        rawt.i <- paste(rawt.i,t.white,sep=",") 
      }
    }
    rawt <- rbind(rawt,c(rownames(dat)[i],rawt.i))
  }
}
write.table(rawt,file=outfile,row.names=F,quote=F,sep="\t")
