#! /usr/bin/perl -w

my $sid       = $ARGV[0];
my $input     = $ARGV[1];
my $refgene   = $ARGV[2];
my $ai_thresh_di = $ARGV[3];
my $ai_thresh_cnv = $ARGV[4];
my $pvalue    = $ARGV[5];
my $cnv_loh_action = $ARGV[6];
my $output    = $ARGV[7];
my $covg_rna = $ARGV[8];

$covg_rna = 3 if $covg_rna < 3;  ### 2019-04-08.

my (%gene,@gene,%chr2g,%g2ase,$head);
my $infile = $refgene;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    push @gene, $F[1];
    $chr2g{$F[2]}{$F[1]} = 1;
    $gene{$F[1]}{chrom} = $F[2];
    $gene{$F[1]}{strand} = $F[3];
    $gene{$F[1]}{start} = $F[4];
    $gene{$F[1]}{end} = $F[5];
    $gene{$F[1]}{name} = $F[12];
    $gene{$F[1]}{cdsstartstat} = $F[13];
    $gene{$F[1]}{cdsendstat} = $F[14];
}
close IN;

open IN, "< $input" or die "$input: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        $head = $_;
        next;
    }
    my @F = split/\t/;
    my $ai = $F[12];
    my $pval = $F[11];
    my $tag = $F[8];
    my $chrom = $F[0];
    my $pos = $F[1];
    my $maf_rna = $F[7];
    my $ase = "no";
    my $snv4 = "$F[0].$F[1].$F[2].$F[3]";
    next unless $F[6] >= $covg_rna;  ### 2019-04-08.
    if ($cnv_loh_action eq "drop" and $tag eq "cnvloh") {
        next;
    }
    if ($tag eq "diploid") {
        if ($ai >= $ai_thresh_di and $pval < $pvalue) {
            $ase = "yes";
        }
    }elsif ($tag eq "cnvloh") {
        if ($ai >= $ai_thresh_cnv and $pval < $pvalue) {
            $ase = "yes";
        }
    }else {
        print "Error: wrong tag $tag for $snv4.\n";
    }
    for my $g (keys %{$chr2g{$chrom}}) {
        if ($pos >= $gene{$g}{start} and $pos <= $gene{$g}{end}) {
            $g2ase{$g}{$snv4}{ai} = $ai;
            $g2ase{$g}{$snv4}{ase} = $ase;
            $g2ase{$g}{$snv4}{pval} = $pval;
            $g2ase{$g}{$snv4}{tag} = $tag;
            $g2ase{$g}{$snv4}{mafrna} = $maf_rna;
        }
    }
}
close IN;

my $outfile = $output;
open OUT, "> $outfile" or die "$outfile: $!";
print OUT "gene\tgsym\tchrom\tstrand\tstart\tend\tcdsStartStat\tcdsEndStat\tmarkers\tase_markers\taverage_ai_all\taverage_ai_ase\tpval_all_markers\tpval_ase_markers\tai_all_markers\tai_ase_markers\ttag_all_markers\tmaf_rna_all_markers\n";
for my $g (@gene) {
    my $markers = 0;
    my $ase_markers = 0;
    my $avg_all = "na";
    my $avg_ase = "na";
    my $p_all = "na";
    my $p_ase = "na";
    my $ai_all = "na";
    my $ai_ase = "na";
    my $tag_all = "na";
    my $maf_rna_all = "na";
    if ($g2ase{$g}) {
        my @markers = sort keys %{$g2ase{$g}};
        my $sum1 = 0;
        my $sum2 = 0;
        for my $m (@markers) {
            $markers++;
            $sum1 += $g2ase{$g}{$m}{ai};
            if ($p_all eq "na") {
                $p_all = $g2ase{$g}{$m}{pval};
                $ai_all = $g2ase{$g}{$m}{ai};
                $tag_all = $g2ase{$g}{$m}{tag};
                $maf_rna_all = $g2ase{$g}{$m}{mafrna};
            }else {
                $p_all .= ",$g2ase{$g}{$m}{pval}";
                $ai_all .= ",$g2ase{$g}{$m}{ai}";
                $tag_all .= ",$g2ase{$g}{$m}{tag}";
                $maf_rna_all .= ",$g2ase{$g}{$m}{mafrna}";
            }
            if ($g2ase{$g}{$m}{ase} eq "yes") {
                $ase_markers++;
                $sum2 += $g2ase{$g}{$m}{ai};
                if ($p_ase eq "na") {
                    $p_ase = $g2ase{$g}{$m}{pval};
                    $ai_ase = $g2ase{$g}{$m}{ai};
                }else {
                    $p_ase .= ",$g2ase{$g}{$m}{pval}";
                    $ai_ase .= ",$g2ase{$g}{$m}{ai}";
                }
            }
        }
        $avg_all = sprintf("%.3f",$sum1/$markers);
        if ($ase_markers > 0) {
            $avg_ase = sprintf("%.3f",$sum2/$ase_markers);
        }
    }
    print OUT "$g\t$gene{$g}{name}\t$gene{$g}{chrom}\t$gene{$g}{strand}\t$gene{$g}{start}\t$gene{$g}{end}\t$gene{$g}{cdsstartstat}\t$gene{$g}{cdsendstat}\t$markers\t$ase_markers\t$avg_all\t$avg_ase\t$p_all\t$p_ase\t$ai_all\t$ai_ase\t$tag_all\t$maf_rna_all\n";
}
close OUT;
