#! /usr/bin/perl -w

my $thresh_ase_pvalue    = $ARGV[0];
my $thresh_ase_delta_di  = $ARGV[1];
my $thresh_ase_delta_cnv = $ARGV[2];
my $thresh_fpkm          = $ARGV[3];
my $thresh_loo_pvalue    = $ARGV[4];
my $sid                  = $ARGV[5];
my $outfile              = $ARGV[6];
my $ase_result_gene      = $ARGV[7];
my $ohe_result           = $ARGV[8];
my $thresh_loo_hi_perc   = $ARGV[9];
my $imprinting_genes     = $ARGV[10];

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
    my $tag = $F[16];
    my @tag = split(/,/,$tag);
    my $tagnum = scalar(@tag);
    my $tagcnv = 0;
    for my $t (@tag) {
        if ($t eq "cnvloh") {
            $tagcnv++;
        }
    }
    my $class = "diploid";
    if ($tagcnv/$tagnum > 0.3) {
        $class = "cnvloh";
    }
#    next unless $g2loo{$F[1]}{pval} < $thresh_loo_pvalue;
    if ($F[21] < $thresh_ase_pvalue) {
        if ($class eq "cnvloh") {
            ### use $thresh_ase_delta_cnv if > 30% of the markers sits in cnvloh region.
            if ($F[18] >= $thresh_ase_delta_cnv) {
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
        }else {
            if ($F[18] >= $thresh_ase_delta_di) {
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
    }
    next unless $candidate_group eq "ase_outlier";
    print OUT "$_\t$g2loo{$F[1]}{fpkm}\t$g2loo{$F[1]}{source}\t$g2loo{$F[1]}{size}\t$g2loo{$F[1]}{pval}\t$g2loo{$F[1]}{rank}\t$imprint\t$candidate_group\n";
}
close IN;

