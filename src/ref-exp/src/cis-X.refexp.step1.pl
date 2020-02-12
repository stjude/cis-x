#! /usr/bin/perl -w

my $config  = $ARGV[0];
my $workdir = $ARGV[1];
my $chr_string = $ARGV[2];

unless ($config and $workdir and $chr_string) {
    die("Usage: cis-X.refexp.step1.pl [config file] [working dir] [chr-string]");
}

my $outfile = "$workdir/cis-X.refexp.step1.commands.sh";
open OUT, "> $outfile" or die "$outfile: $!";
open IN, "< $config" or die "$config: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    print OUT "cis-X ref-exp preprocess $F[0] $workdir $F[1] $F[2] $F[3] $chr_string\n";
}
close IN;
close OUT;

