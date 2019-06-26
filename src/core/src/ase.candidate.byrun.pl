#! /usr/bin/perl -w

my $sid                  = $ARGV[0];
my $thresh_fpkm          = $ARGV[1];
my $thresh_loo_pvalue    = $ARGV[2];
my $ase_result_run       = $ARGV[3];
my $ohe_result           = $ARGV[4];
my $outfile              = $ARGV[5];
my $imprinting_genes     = $ARGV[6];
my $oncogenes            = $ARGV[7];
my $num_markers          = $ARGV[8];
my $ase_result_gene      = $ARGV[9];
my $thresh_ase_delta_di  = $ARGV[10];
my $thresh_ase_delta_cnv = $ARGV[11];

my (%imprint,%g2loo,%glst,%oncog,%g2ase);

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

$infile = $ase_result_gene;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $g2ase{$F[1]}{pval} = $F[20];   ### using raw p here.
    $g2ase{$F[1]}{delta} = $F[19];
    $g2ase{$F[1]}{tag} = $F[16];
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

$infile = $ase_result_run;
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $outfile" or die "$outfile: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "$_\tCandidates\n";
        next;
    }
    my @F = split/\t/;
    next unless $F[5] >= $num_markers;
    if ($F[7]) {
        my @G = split(/,/,$F[7]);
        my $candidates = "";
        for my $g (@G) {
            if ($imprint{$g} and ($imprint{$g} eq "Imprinted")) {
                next;
            }
            next unless $g2loo{$g};
            my $keep = 0;
            if ($g2loo{$g}{fpkm} >= $thresh_fpkm and $g2loo{$g}{pval} < $thresh_loo_pvalue) {
                $keep = 1;
            }elsif ($oncog{$g} and $g2loo{$g}{fpkm} >= 1 and $g2loo{$g}{pval} < $thresh_loo_pvalue) {
                 $keep = 1;
            }else {
                next;
            }
            if ($keep == 1) {
                if ($g2ase{$g}) {
                    my @tag = split(/,/,$g2ase{$g}{tag});
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
                    if ($class eq "diploid") {
                        if ($g2ase{$g}{pval} < 0.1 and $g2ase{$g}{delta} >= $thresh_ase_delta_di) {
                            $candidates .= "$g,";
                        }
                    }elsif ($class eq "cnvloh") {
                        if ($g2ase{$g}{pval} < 0.1 and $g2ase{$g}{delta} >= $thresh_ase_delta_cnv) {
                            $candidates .= "$g,";
                        }
                    }else {
                        print "Wrong class for $class.\n";
                        next;
                    }
                }else {
                    $candidates .= "$g,";
                }
            }
        }
        $candidates =~ s/\,$//;
        print OUT "$_\t$candidates\n";
    }else {
        print OUT "$_\t\n";
    }
}
close IN;
close OUT;
