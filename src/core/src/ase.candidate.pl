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
my $oncogenes            = $ARGV[11];

my (%imprint,%g2loo,%glst,%oncog);

my $infile = $imprinting_genes;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $imprint{$F[0]} = $F[3];
}
close IN;

$infile = $oncogenes;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    $_ =~ s/\"//g;
    my @F = split/\t/;
    next unless $F[14];
    next if $F[14] eq "TSG";
    next if $F[0] eq "IGH" or $F[0] eq "IGK" or $F[0] eq "IGL" or $F[0] eq "HLA-A";
    $oncog{$F[0]} = $F[14];
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
        print OUT "$_\tFPKM\tloo.source\tloo.cohort.size\tloo.pval\tloo.rank\timprinting.status\tcandidate.group\tdescription\n";
        next;
    }
    my @F = split/\t/;
    my $imprint = "";
    my $candidate_group = "";
    my $description = "";
    if ($imprint{$F[1]}) {
        $imprint = $imprint{$F[1]};
    }
    next if $imprint eq "Imprinted";
    next unless $g2loo{$F[1]};
    $glst{$F[1]} = 1;
    ### 2018/12/25, for the known oncogenes in cosmic, keep for next step if p-value pass the threshold and fpkm >= 1.
    if ($g2loo{$F[1]}{fpkm} >= $thresh_fpkm) {
        1;
    }elsif ($oncog{$F[1]} and $g2loo{$F[1]}{fpkm} >= 1) {
        $description = "rescued-ohe";
    }else {
        next;
    }
#    next unless $g2loo{$F[1]}{fpkm} >= $thresh_fpkm;
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
    if ($F[22] < $thresh_ase_pvalue) {
        if ($class eq "cnvloh") {
            ### use $thresh_ase_delta_cnv if > 30% of the markers sits in cnvloh region.
            if ($F[19] >= $thresh_ase_delta_cnv) {
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
            if ($F[19] >= $thresh_ase_delta_di) {
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
        if ($oncog{$F[1]}) {
            if ($description) {
                $description = "$oncog{$F[1]}, $description";
            }else {
                $description = "$oncog{$F[1]}";
            }
        }
    }else {
        ### for the known oncogenes in cosmic, rescue if raw p-value < 0.05 && over 90% of markers show mono-allelic transcription (maf-rna < 0.1 || maf-rna > 0.9).
        my $keep = 1;
        if ($oncog{$F[1]} and $F[20] < 0.05) {
            my @mafrna = split(/,/,$F[17]);
            my $rnasig = 0;
            my $rnatot = scalar(@mafrna);
            for my $f (@mafrna) {
                if ($f > 0.9 or $f < 0.1) {
                    $rnasig++;
                }
            }
            if ($rnasig/$rnatot < 0.9) {
                $keep = 0;
            }
        }else {
            $keep = 0;
        }
        if ($keep == 1) {
            if ($class eq "cnvloh") {
            ### use $thresh_ase_delta_cnv if > 30% of the markers sits in cnvloh region.
                if ($F[19] >= $thresh_ase_delta_cnv) {
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
                if ($F[19] >= $thresh_ase_delta_di) {
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
            if ($description) {
                $description = "$oncog{$F[1]}, rescued-ase, $description";
            }else {
                $description = "$oncog{$F[1]}, rescued-ase";
            }
        }
    }
    next unless $candidate_group eq "ase_outlier";
    print OUT "$_\t$g2loo{$F[1]}{fpkm}\t$g2loo{$F[1]}{source}\t$g2loo{$F[1]}{size}\t$g2loo{$F[1]}{pval}\t$g2loo{$F[1]}{rank}\t$imprint\t$candidate_group\t$description\n";
}
close IN;
