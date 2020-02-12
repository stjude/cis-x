#! /usr/bin/perl -w

my $workdir = $ARGV[0];
my $expfile = $ARGV[1];

my $outdir = "$workdir/refexp";
system "mkdir -p $outdir";

my $infile = "$workdir/cis-X.refexp.step2.collect.filtered.bi.samples.cleared.txt";
my $outfile = "$outdir/exp.ref.bi.txt";
open OUT, "> $outfile" or die "$outfile: $!";
print OUT "Gene\tnum.cases\tSJID\tfpkm\n";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    if ($F[5]>=10) {
      if ($F[15] == 1) {
          print OUT "$F[0]\t$F[16]\t$F[17]\t$F[18]\n";
      }else {
          print OUT "$F[0]\t$F[5]\t$F[6]\t$F[7]\n";
      }
    }
}
close IN;
close OUT;

$outfile = "$outdir/exp.ref.white.txt";
open OUT, "> $outfile" or die "$outfile: $!";
print OUT "Gene\tnum.cases\tSID\tfpkm\n";
close OUT;

