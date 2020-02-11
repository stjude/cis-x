#! /usr/bin/perl -w

my $input  = $ARGV[0];
my $chrom  = $ARGV[1];
my $output = $ARGV[2];
my $chr_string = $ARGV[3];

open IN, "< $input" or die "$input: $!";
open OUT, "> $output" or die "$output: $!";
while(<IN>) {
    chomp;
    my @F = split(/\./,$_);
    my $snv4 = $_;
    unless ($chr_string eq "TRUE") {
        $snv4 =~ s/^chr//;
    }
    if ($F[0] eq $chrom) {
        print OUT "$snv4\n";
    }
}
close IN;
close OUT;

