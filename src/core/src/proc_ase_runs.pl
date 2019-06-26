#! /usr/bin/perl -w

my $ase_runs = $ARGV[0];
my $ase_runs_gene = $ARGV[1];
my $outfile = $ARGV[2];

my (%run2g);

open IN, "< $ase_runs_gene" or die "$ase_runs_gene: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    next if $F[10] == 0;
    $run2g{$F[3]}{$F[7]} = 1;
}
close IN;

open IN, "< $ase_runs" or die "$ase_runs: $!";
open OUT, "> $outfile" or die "$outfile: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "$_\tGenes_overlap_hc\n";
        next;
    }
    my @F = split/\t/;
    my $gene = "";
    if ($run2g{$F[0]}) {
        my @g = keys %{$run2g{$F[0]}};
        $gene = join(',',@g);
    }
    print OUT "$_\t$gene\n";
}
close IN;
close OUT;
