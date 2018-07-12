#! /usr/bin/perl -w

my $infile = "hg19_refGene";
my $outfile = "hg19_refGene.bed";
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $outfile" or die "$outfile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    print OUT "$F[2]\t$F[4]\t$F[5]\t$F[12]\t$F[1]\t$F[3]\n";
}
close IN;
close OUT;

