#! /usr/bin/perl -w

### to be consistant with previous filter, the promoter was used.
### promoter was defined as 2kb upstream and 200bp downstream of tss, as in doi:10.1038/ng.3101
#### TAD was combined hESC and IMR90 from Bing Ren's paper.

my $sampleid = $ARGV[0];
my $tad_ref  = $ARGV[1];
my $refgene  = $ARGV[2];
my $input    = $ARGV[3];
my $output   = $ARGV[4];

my (%tad,%g2pro);

my $infile = $tad_ref;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    my $id = "$F[0].$F[1].$F[2]";
    $tad{$F[0]}{$id}{start} = $F[1];
    $tad{$F[0]}{$id}{end}   = $F[2];
    $tad{$F[0]}{$id}{source} = "hESC";
}
close IN;

$infile = $refgene;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    next if $F[0] =~ /_random/;
    next if $F[0] =~ /_hap/;
    next if $F[0] =~ /chrUn/;
    if ($F[5] eq "+") {
        $g2pro{$F[3]}{$F[4]}{start} = $F[1] - 2000;
        $g2pro{$F[3]}{$F[4]}{end}   = $F[1] + 200;
        $g2pro{$F[3]}{$F[4]}{chrom} = $F[0];
    }elsif ($F[5] eq "-") {
        $g2pro{$F[3]}{$F[4]}{end}   = $F[2] + 2000;
        $g2pro{$F[3]}{$F[4]}{start} = $F[2] - 200;
        $g2pro{$F[3]}{$F[4]}{chrom} = $F[0];
    }else {
        print "Wrong strand info: $F[5] for $F[4].\n";
    }
}
close IN;

$infile = $input;
my $outfile = $output;
open OUT, "> $outfile" or die "$outfile: $!";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    if ($. == 1) {
        print OUT "left.candidate.inTAD\tright.candidate.inTAD";
        for my $i (4 .. $#F) {
            print OUT "\t$F[$i]";
        }
        print OUT "\n";
        next;
    }
    my $left = "";
    my $right = "";
    if ($F[0]) {
        my $chrom = $F[4];
        unless ($chrom =~ /^chr/) {
            $chrom = "chr" . $chrom;
        }
        my $pos = $F[5];
        my @g = split(/,/,$F[0]);
        for my $tad (sort keys %{$tad{$chrom}}) {
            if ($pos <= $tad{$chrom}{$tad}{end} and $pos >= $tad{$chrom}{$tad}{start}) {
                for my $g (@g) {
                    my $overlap = 0;
                    if ($g2pro{$g}) {
                        for my $acc (sort keys %{$g2pro{$g}}) {
                            if ($g2pro{$g}{$acc}{chrom} ne $chrom) {
                                print "Wrong chromosome for gene $g.\n";
                            }else {
                                if ($g2pro{$g}{$acc}{start} > $tad{$chrom}{$tad}{end}) {
                                    1;
                                }elsif ($g2pro{$g}{$acc}{start} >= $tad{$chrom}{$tad}{start}) {
                                    $overlap = 1;
                                }elsif ($g2pro{$g}{$acc}{end} >= $tad{$chrom}{$tad}{start}) {
                                    $overlap = 1;
                                }else {
                                    1;
                                }
                            }
                        }
                    }else {
                        print "No promoter info for $g.\n";
                    }
                    if ($overlap == 1) {
                        $left .= "$g,";
                    }
                }
            }
        }
    }
    if ($F[2]) {
        my $chrom = $F[7];
        unless ($chrom =~ /^chr/) {
            $chrom = "chr" . $chrom;
        }
        my $pos = $F[8];
        my @g = split(/,/,$F[2]);
        for my $tad (sort keys %{$tad{$chrom}}) {
            if ($pos <= $tad{$chrom}{$tad}{end} and $pos >= $tad{$chrom}{$tad}{start}) {
                for my $g (@g) {
                    my $overlap = 0;
                    if ($g2pro{$g}) {
                        for my $acc (sort keys %{$g2pro{$g}}) {
                            if ($g2pro{$g}{$acc}{chrom} ne $chrom) {
                                print "Wrong chromosome for gene $g.\n";
                            }else {
                                if ($g2pro{$g}{$acc}{start} > $tad{$chrom}{$tad}{end}) {
                                    1;
                                }elsif ($g2pro{$g}{$acc}{start} >= $tad{$chrom}{$tad}{start}) {
                                    $overlap = 1;
                                }elsif ($g2pro{$g}{$acc}{end} >= $tad{$chrom}{$tad}{start}) {
                                    $overlap = 1;
                                }else {
                                    1;
                                }
                            }
                        }
                    }else {
                        print "No promoter info for $g.\n";
                    }
                    if ($overlap == 1) {
                        $right .= "$g,";
                    }
                }
            }
        }
    }
    $left =~ s/\,$//;
    $right =~ s/\,$//;
    if ($left or $right) {
        print OUT "$left\t$right";
        for my $i (4 .. $#F) {
            print OUT "\t$F[$i]";
        }
        print OUT "\n";
    }
}
close IN;
close OUT;

