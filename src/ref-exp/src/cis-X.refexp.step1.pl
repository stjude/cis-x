#! /usr/bin/perl -w

my $config  = $ARGV[0];
my $workdir = $ARGV[1];

unless ($config and $workdir) {
    die("Usage: cis-X.refexp.step1.pl [config file] [working dir]");
}

my $outfile = "$workdir/cis-X.refexp.step1.commands.sh";
open OUT, "> $outfile" or die "$outfile: $!";
open IN, "< $config" or die "$config: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    print OUT "cis-X refexp preprocess $F[0] $workdir $F[1] $F[2] $F[3]\n";
}
close IN;
close OUT;

