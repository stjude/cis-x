#! /usr/bin/perl -w

my $input  = $ARGV[0];
my $chrom  = $ARGV[1];
my $output = $ARGV[2];

open IN, "< $input" or die "$input: $!";
open OUT, "> $output" or die "$output: $!";
while(<IN>) {
    chomp;
    my @F = split(/\./,$_);
    if ($F[0] eq $chrom) {
        print OUT "$_\n";
    }
}
close IN;
close OUT;

