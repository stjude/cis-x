
argv <- commandArgs(TRUE)

sample <- argv[1]
fpkm_in <- argv[2]
ref_bi_in <- argv[3]
ref_cohort_in <- argv[4]
ref_white_in <- argv[5]
outfile <- argv[6]
precalt <- argv[7]

fpkm.raw <- read.table(fpkm_in,sep="\t",header=T,row.names=2,quote="",stringsAsFactors=F)
if (!sample %in% colnames(fpkm.raw)) {
    stop("sample not present in fpkm matrix.")
}
fpkm.sid <- fpkm.raw[,sample]
names(fpkm.sid) <- rownames(fpkm.raw)

ref.bi <- read.table(ref_bi_in,sep="\t",row.names=1,quote="",header=T,stringsAsFactors=F)
ref.cohort <- read.table(ref_cohort_in,sep="\t",header=T,row.names=2,quote="",stringsAsFactors=F)
ref.white <- read.table(ref_white_in,sep="\t",row.names=1,quote="",header=T,stringsAsFactors=F)
ref.rawtval <- read.table(precalt,sep="\t",stringsAsFactors=F)
ref.t <- ref.rawtval[,1]
ref.t.total <- length(ref.t)

out <- NULL
for (i in 1:length(fpkm.sid)) {
  x.i <- fpkm.sid[i]
  x.i.raw <- x.i
  g.i <- names(fpkm.sid)[i]
  y.bi.raw <- NULL
  y.bi.sid <- NULL
  y.bi <- NULL
  t.bi <- NULL
  r.bi <- NULL
  p.bi <- NULL
  l.bi <- NULL
  t.bi.perc <- NULL
  y.cohort.raw <- NULL
  y.cohort.sid <- NULL
  y.cohort <- NULL
  t.cohort <- NULL
  r.cohort <- NULL
  p.cohort <- NULL
  l.cohort <- NULL
  t.cohort.perc <- NULL
  y.white.raw <- NULL
  y.white.sid <- NULL
  y.white <- NULL
  t.white <- NULL
  r.white <- NULL
  p.white <- NULL
  l.white <- NULL
  t.white.perc <- NULL
  if (x.i > 0) {
    x.i <- log10(x.i+0.1)
    if (g.i %in% rownames(ref.bi)) {
      y.bi.raw <- log10(as.numeric(unlist(strsplit(ref.bi[g.i,3],",",perl=T)))+0.1)
            y.bi.sid <- unlist(strsplit(ref.bi[g.i,2],",",perl=T))
            if (sample %in% y.bi.sid) {
              y.bi <- y.bi.raw[!y.bi.sid %in% sample]
            }else {
              y.bi <- y.bi.raw
            }
      t.bi <- (x.i-mean(y.bi))/((1+(length(y.bi)-2)^-1)*(sd(y.bi)^2))^0.5
      p.bi <- pt(t.bi,length(y.bi)-2,lower.tail=F)
      r.bi <- length(y.bi[y.bi>x.i])+1
      l.bi <- length(y.bi)
      t.bi.perc <- (length(ref.t[ref.t>t.bi])+1)/ref.t.total
    }
    if (g.i %in% rownames(ref.white)) {
      y.white.raw <- log10(as.numeric(unlist(strsplit(ref.white[g.i,3],",",perl=T)))+0.1)
            y.white.sid <- unlist(strsplit(ref.white[g.i,2],",",perl=T))
            if (sample %in% y.white.sid) {
              y.white <- y.white.raw[!y.white.sid %in% sample]
            }else {
              y.white <- y.white.raw
            }
      t.white <- (x.i-mean(y.white))/((1+(length(y.white)-2)^-1)*(sd(y.white)^2))^0.5
      p.white <- pt(t.white,length(y.white)-2,lower.tail=F)
      r.white <- length(y.white[y.white>x.i])+1
      l.white <- length(y.white)
      t.white.perc <- (length(ref.t[ref.t>t.white])+1)/ref.t.total
    }
    if (g.i %in% rownames(ref.cohort)) {
      y.cohort.raw <- log10(as.numeric(ref.cohort[g.i,7:ncol(ref.cohort)])+0.1)
      y.cohort.sid <- colnames(ref.cohort)[7:ncol(ref.cohort)]
      if (sample %in% y.cohort.sid) {
              y.cohort <- y.cohort.raw[!y.cohort.sid %in% sample]
            }else {
              y.cohort <- y.cohort.raw
            }
      t.cohort <- (x.i-mean(y.cohort))/((1+(length(y.cohort)-2)^-1)*(sd(y.cohort)^2))^0.5
      p.cohort <- pt(t.cohort,length(y.cohort)-2,lower.tail=F)
      r.cohort <- length(y.cohort[y.cohort>x.i])+1
      l.cohort <- length(y.cohort)
      t.cohort.perc <- (length(ref.t[ref.t>t.cohort])+1)/ref.t.total
    }
    if (is.null(p.bi)) {p.bi <- "na"}
    if (is.null(r.bi)) {r.bi <- "na"}
    if (is.null(l.bi)) {l.bi <- "na"}
    if (is.null(t.bi)) {t.bi <- "na"}
    if (is.null(t.bi.perc)) {t.bi.perc <- "na"}
    if (is.null(p.white)) {p.white <- "na"}
    if (is.null(r.white)) {r.white <- "na"}
    if (is.null(l.white)) {l.white <- "na"}
    if (is.null(t.white)) {t.white <- "na"}
    if (is.null(t.white.perc)) {t.white.perc <- "na"}
    if (is.null(p.cohort)) {p.cohort <- "na"}
    if (is.null(r.cohort)) {r.cohort <- "na"}
    if (is.null(l.cohort)) {l.cohort <- "na"}
    if (is.null(t.cohort)) {t.cohort <- "na"}
    if (is.null(t.cohort.perc)) {t.cohort.perc <- "na"}
    out <- rbind(out,c(g.i,x.i.raw,l.bi,p.bi,r.bi,t.bi,t.bi.perc,l.cohort,p.cohort,r.cohort,t.cohort,t.cohort.perc,l.white,p.white,r.white,t.white,t.white.perc))
  }
}
colnames(out) <- c("Gene","fpkm.raw","size.bi","p.bi","rank.bi","tstatistic.bi","qval.bi","size.cohort","p.cohort","rank.cohort","tstatistic.cohort","qval.cohort","size.white","p.white","rank.white","tstatistic.white","qval.white")
write.table(out,file=outfile,sep="\t",row.names=F,quote=F)
