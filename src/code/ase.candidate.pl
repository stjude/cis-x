#! /usr/bin/perl -w

my $thresh_ase_pvalue = $ARGV[0];
my $thresh_ase_delta  = $ARGV[1];
my $thresh_fpkm       = $ARGV[2];
my $thresh_loo_pvalue = $ARGV[3];
my $sid               = $ARGV[4];
my $outfile           = $ARGV[5];
my $ase_result_gene   = $ARGV[6];
my $ohe_result        = $ARGV[7];
my $thresh_loo_hi_perc= $ARGV[8];
my $imprinting_genes  = $ARGV[9];

my (%imprint,%g2loo,%glst);

my $infile = $imprinting_genes;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $imprint{$F[0]} = $F[3];
}
close IN;

$infile = $ohe_result;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $g2loo{$F[0]}{fpkm} = $F[1];
    if ($F[8] ne "na") {
        $g2loo{$F[0]}{pval} = $F[9];
        $g2loo{$F[0]}{rank} = $F[10];
        $g2loo{$F[0]}{size} = $F[8];
        $g2loo{$F[0]}{source} = "white_list";
    }elsif ($F[2] ne "na") {
        $g2loo{$F[0]}{pval} = $F[3];
        $g2loo{$F[0]}{rank} = $F[4];
        $g2loo{$F[0]}{size} = $F[2];
        $g2loo{$F[0]}{source} = "bi_cohort";
    }else {
        $g2loo{$F[0]}{pval} = $F[6];
        $g2loo{$F[0]}{rank} = $F[7];
        $g2loo{$F[0]}{size} = $F[5];
        $g2loo{$F[0]}{source} = "entire_cohort";
    }
}
close IN;

$infile = $ase_result_gene;
open OUT, "> $outfile" or die "$outfile: $!";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "$_\tFPKM\tloo.source\tloo.cohort.size\tloo.pval\tloo.rank\timprinting.status\tcandidate.group\n";
        next;
    }
    my @F = split/\t/;
    my $imprint = "";
    my $candidate_group = "";
    if ($imprint{$F[1]}) {
        $imprint = $imprint{$F[1]};
    }
    next unless $g2loo{$F[1]};
    $glst{$F[1]} = 1;
    next unless $g2loo{$F[1]}{fpkm} >= $thresh_fpkm;
#    next unless $g2loo{$F[1]}{pval} < $thresh_loo_pvalue;
    if ($F[20] < $thresh_ase_pvalue) {
        if ($F[17] >= $thresh_ase_delta) {
            if ($g2loo{$F[1]}{pval} < $thresh_loo_pvalue) {
                $candidate_group = "ase_outlier";
            }elsif ($g2loo{$F[1]}{rank}/$g2loo{$F[1]}{size} <= $thresh_loo_hi_perc) {
                $candidate_group = "ase_high";
            }else {
                1;
            }
        }else {
            if ($g2loo{$F[1]}{pval} < $thresh_loo_pvalue) {
                $candidate_group = "uncertain_outlier";
            }else {
                1;
            }
        }
    }
    next unless $candidate_group;
    print OUT "$_\t$g2loo{$F[1]}{fpkm}\t$g2loo{$F[1]}{source}\t$g2loo{$F[1]}{size}\t$g2loo{$F[1]}{pval}\t$g2loo{$F[1]}{rank}\t$imprint\t$candidate_group\n";
}
close IN;

