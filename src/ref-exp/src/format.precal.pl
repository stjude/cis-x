#! /usr/bin/perl -w

my $workdir = $ARGV[0];

my $infile = "$workdir/raw.tvalue.bicohort.txt";
my $outfile = "$workdir/refexp/precal.tvalue.bin_gt1.txt";
open OUT, "> $outfile" or die "$outfile: $!";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my @f = split(/,/,$F[1]);
    for my $f (@f) {
        next if $f eq "NaN";
        print OUT "$f\n";
    }
}
close IN;
close OUT;
