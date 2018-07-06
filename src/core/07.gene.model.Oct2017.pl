#! /usr/bin/perl -w

my $sid       = $ARGV[0];
my $input     = $ARGV[1];
my $refgene   = $ARGV[2];
my $ai_thresh = $ARGV[3];
my $pvalue    = $ARGV[4];
my $output    = $ARGV[5];

my (%gene,@gene,%chr2g,%g2ase,%drop,$head);
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
    my $ai = $F[11];
    my $pval = $F[10];
    my $chrom = $F[0];
    my $pos = $F[1];
    my $ase = "no";
    my $drop = 1;
    if ($ai >= $ai_thresh and $pval < $pvalue) {
        $ase = "yes";
    }
    my $snv4 = "$F[0].$F[1].$F[2].$F[3]";
    for my $g (keys %{$chr2g{$chrom}}) {
        if ($pos >= $gene{$g}{start} and $pos <= $gene{$g}{end}) {
            $g2ase{$g}{$snv4}{ai} = $ai;
            $g2ase{$g}{$snv4}{ase} = $ase;
            $g2ase{$g}{$snv4}{pval} = $pval;
            $drop = 0;
        }
    }
    if ($drop) {
        $drop{$snv4} = $_;
    }
}
close IN;

my $outfile = $output;
open OUT, "> $outfile" or die "$outfile: $!";
print OUT "gene\tgsym\tchrom\tstrand\tstart\tend\tcdsStartStat\tcdsEndStat\tmarkers\tase_markers\taverage_ai_all\taverage_ai_ase\tpval_all_markers\tpval_ase_markers\tai_all_markers\tai_ase_markers\n";
for my $g (@gene) {
    my $markers = 0;
    my $ase_markers = 0;
    my $avg_all = "na";
    my $avg_ase = "na";
    my $p_all = "na";
    my $p_ase = "na";
    my $ai_all = "na";
    my $ai_ase = "na";
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
            }else {
                $p_all .= ",$g2ase{$g}{$m}{pval}";
                $ai_all .= ",$g2ase{$g}{$m}{ai}";
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
    print OUT "$g\t$gene{$g}{name}\t$gene{$g}{chrom}\t$gene{$g}{strand}\t$gene{$g}{start}\t$gene{$g}{end}\t$gene{$g}{cdsstartstat}\t$gene{$g}{cdsendstat}\t$markers\t$ase_markers\t$avg_all\t$avg_ase\t$p_all\t$p_ase\t$ai_all\t$ai_ase\n";
}
close OUT;

