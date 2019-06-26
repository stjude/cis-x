#! /usr/bin/perl -w
### updated 2019-04-08.

my $infile    = $ARGV[0];
my $delta_di  = $ARGV[1];
my $delta_cnv = $ARGV[2];
my $outfile   = $ARGV[3];
my $bedfile   = $ARGV[4];
my $num_markers = $ARGV[5];
my $frac_markers = $ARGV[6];
my $dist_markers = $ARGV[7];

my $cluster = 0;

print "$frac_markers\n";

#my $num_markers  = 15;      ### at least 4 markers to call a run.
#my $frac_markers = 0.75;    ### minimal 75% of markers to be "s" or "e" to call a run.
#my $dist_markers = 200000; ### markers separated over 200kb will not be joined into a run.

my (%runs,%buff,$last1,$last2);
my $buff = 0;

open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my $tag = "f";

    if ($F[10] == 0 or $F[9] == 0) {
        $tag = "e";  ### extreme
    }elsif (($F[10] == 1 and $F[9] >= 4) or ($F[9] == 1 and $F[10] >= 4)) {
        if ($F[11] <= 0.05) {
            $tag = "e";  ### extreme with error but significant
        }else {
            $tag = "E";  ### extreme with error
        }
    }elsif ($F[11] <= 0.05) {
        if ($F[8] eq "diploid") {
            if ($F[12] >= $delta_di) {
                $tag = "s";  ### significant
            }
        }elsif ($F[8] eq "cnvloh") {
            if ($F[12] >= $delta_cnv) {
                $tag = "s";  ### significant
            }
        }else {
            print "Error: wrong tag for $F[8] at $F[0] $F[1].\n";
        }
    }else {
        1;
    }

    if ($tag eq "s" or $tag eq "e" or $tag eq "E") {
        if ($buff == 0) {
            $buff = 1;
            $buff{chrom} = $F[0];
            $buff{pos}   = $F[1];
            $buff{tags}  = $tag;
        }elsif ($F[0] ne $buff{chrom}) {
            my @t = split(//,$buff{tags});
            my $num = 0;
            my $perc = 0;
            my $numE = 0;
            my $percE = 0;
            my $totm = scalar(@t);
            for my $m (@t) {
                $num++ if ($m eq "s" or $m eq "e");
                $numE++ if $m eq "E";
            }
            $perc = $num / $totm;
            $percE = $numE / $totm;
            if ($totm >= $num_markers and $perc >= $frac_markers and $percE < 1) {
                $cluster++;
                if ($t[$#t] ne "f" and $t[$#t-1] ne "f") {
                    my @pos = split(/,/,$buff{pos});
                    $runs{$cluster}{chrom} = $buff{chrom};
                    $runs{$cluster}{start} = $pos[0];
                    $runs{$cluster}{end}   = $pos[$#pos];
                    $runs{$cluster}{tags}  = $buff{tags};
                }elsif ($t[$#t] eq "f") {
                    my @pos = split(/,/,$buff{pos});
                    $runs{$cluster}{chrom} = $buff{chrom};
                    $runs{$cluster}{start} = $pos[0];
                    $runs{$cluster}{end}   = $pos[$#pos-1];
                    for my $i (0 .. $#t-1) {
                        $runs{$cluster}{tags}  .= "$t[$i]";
                    }
                }elsif ($t[$#t-1] eq "f") {
                    my @pos = split(/,/,$buff{pos});
                    $runs{$cluster}{chrom} = $buff{chrom};
                    $runs{$cluster}{start} = $pos[0];
                    $runs{$cluster}{end}   = $pos[$#pos-2];
                    for my $i (0 .. $#t-2) {
                        $runs{$cluster}{tags}  .= "$t[$i]";
                    }
                }else {
                    print "Warning: $buff{tags}\n";
                }
            }
            %buff = ();
            $buff = 1;
            $buff{chrom} = $F[0];
            $buff{pos}   = $F[1];
            $buff{tags}  = $tag;
        }else {
            my @pos = split(/,/,$buff{pos});
            if ($F[1] - $pos[$#pos] <= $dist_markers) {
                $buff{pos}  .= ",$F[1]";
                $buff{tags} .= $tag;
            }else {
                my @t = split(//,$buff{tags});
                my $num = 0;
                my $perc = 0;
                my $numE = 0;
                my $percE = 0;
                my $totm = scalar(@t);
                for my $m (@t) {
                    $num++ if ($m eq "s" or $m eq "e");
                    $numE++ if $m eq "E";
                }
                $perc = $num / $totm;
                $percE = $numE / $totm;
                if ($totm >= $num_markers and $perc >= $frac_markers and $percE < 1) {
                    $cluster++;
                    if ($t[$#t] ne "f" and $t[$#t-1] ne "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos];
                        $runs{$cluster}{tags}  = $buff{tags};
                    }elsif ($t[$#t] eq "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos-1];
                        for my $i (0 .. $#t-1) {
                            $runs{$cluster}{tags}  .= "$t[$i]";
                        }
                    }elsif ($t[$#t-1] eq "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos-2];
                        for my $i (0 .. $#t-2) {
                            $runs{$cluster}{tags}  .= "$t[$i]";
                        }
                    }else {
                        print "Warning: $buff{tags}\n";
                    }
                }
                %buff = ();
                $buff = 1;
                $buff{chrom} = $F[0];
                $buff{pos}   = $F[1];
                $buff{tags}  = $tag;
            }
        }
    }else {
        if ($buff == 1) {
            if ($F[0] ne $buff{chrom}) {
                my @t = split(//,$buff{tags});
                my $num = 0;
                my $perc = 0;
                my $numE = 0;
                my $percE = 0;
                my $totm = scalar(@t);
                for my $m (@t) {
                    $num++ if ($m eq "s" or $m eq "e");
                    $numE++ if $m eq "E";
                }
                $perc = $num / $totm;
                $percE = $numE/ $totm;
                if ($totm >= $num_markers and $perc >= $frac_markers and $percE < 1) {
                    $cluster++;
                    if ($t[$#t] ne "f" and $t[$#t] ne "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos];
                        $runs{$cluster}{tags}  = $buff{tags};
                    }elsif ($t[$#t] eq "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos-1];
                        for my $i (0 .. $#t-1) {
                            $runs{$cluster}{tags}  .= "$t[$i]";
                        }
                    }elsif ($t[$#t-1] eq "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos-2];
                        for my $i (0 .. $#t-2) {
                            $runs{$cluster}{tags}  .= "$t[$i]";
                        }
                    }else {
                        print "Warning: $buff{tags}\n";
                    }
                }else {
                    1;
                }
                $buff = 0;
                %buff = ();
            }elsif ($last1 ne "f" and $last2 ne "f") {
                my @pos = split(/,/,$buff{pos});
                if ($F[1] - $pos[$#pos] <= $dist_markers) {
                    $buff{pos}  .= ",$F[1]";
                    $buff{tags} .= $tag;
                }else {
                    my @t = split(//,$buff{tags});
                    my $num = 0;
                    my $perc = 0;
                    my $numE = 0;
                    my $percE = 0;
                    my $totm = scalar(@t);
                    for my $m (@t) {
                        $num++ if ($m eq "s" or $m eq "e");
                        $numE++ if $m eq "E";
                    }
                    $perc = $num / $totm;
                    $percE = $numE/ $totm;
                    if ($totm >= $num_markers and $perc >= $frac_markers and $percE < 1) {
                        $cluster++;
                        if ($t[$#t] ne "f" and $t[$#t] ne "f") {
                            my @pos = split(/,/,$buff{pos});
                            $runs{$cluster}{chrom} = $buff{chrom};
                            $runs{$cluster}{start} = $pos[0];
                            $runs{$cluster}{end}   = $pos[$#pos];
                            $runs{$cluster}{tags}  = $buff{tags};
                        }elsif ($t[$#t] eq "f") {
                            my @pos = split(/,/,$buff{pos});
                            $runs{$cluster}{chrom} = $buff{chrom};
                            $runs{$cluster}{start} = $pos[0];
                            $runs{$cluster}{end}   = $pos[$#pos-1];
                            for my $i (0 .. $#t-1) {
                                $runs{$cluster}{tags}  .= "$t[$i]";
                            }
                        }elsif ($t[$#t-1] eq "f") {
                            my @pos = split(/,/,$buff{pos});
                            $runs{$cluster}{chrom} = $buff{chrom};
                            $runs{$cluster}{start} = $pos[0];
                            $runs{$cluster}{end}   = $pos[$#pos-2];
                            for my $i (0 .. $#t-2) {
                                $runs{$cluster}{tags}  .= "$t[$i]";
                            }
                        }else {
                            print "Warning: $buff{tags}\n";
                        }
                    }else {
                        1;
                    }
                    $buff = 0;
                    %buff = ();
                }
            }else {
                my @t = split(//,$buff{tags});
                my $num = 0;
                my $perc = 0;
                my $numE = 0;
                my $percE = 0;
                my $totm = scalar(@t);
                for my $m (@t) {
                    $num++ if ($m eq "s" or $m eq "e");
                    $numE++ if $m eq "E";
                }
                $perc = $num / $totm;
                $percE = $numE/ $totm;
                if ($totm >= ($num_markers+1) and $perc >= $frac_markers and $percE < 1) {
                    $cluster++;
                    if ($t[$#t] eq "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos-1];
                        for my $i (0 .. $#t-1) {
                            $runs{$cluster}{tags}  .= "$t[$i]";
                        }
                    }elsif ($t[$#t-1] eq "f") {
                        my @pos = split(/,/,$buff{pos});
                        $runs{$cluster}{chrom} = $buff{chrom};
                        $runs{$cluster}{start} = $pos[0];
                        $runs{$cluster}{end}   = $pos[$#pos-2];
                        for my $i (0 .. $#t-2) {
                            $runs{$cluster}{tags}  .= "$t[$i]";
                        }
                    }else {
                        print "Warning: $buff{tags}\n";
                    }
                }else {
                    1;
                }
                $buff = 0;
                %buff = ();
            }
        }else {
            1;
        }
    }

    if ($. == 2) {
        $last1 = $tag;
        $last2 = $last1;
    }else {
        $last2 = $last1;
        $last1 = $tag;
    }
}
close IN;

open OUT, "> $outfile" or die "$outfile: $!";
open BED, "> $bedfile" or die "$bedfile: $!";
print OUT "Run_ID\tChrom\tStart\tEnd\tLength\tNum_Markers\tTag_Markers\n";
for my $c (sort {$a <=> $b} keys %runs) {
    my $len = $runs{$c}{end} - $runs{$c}{start};
    my $num = scalar(split(//,$runs{$c}{tags}));
    print OUT "$c\t$runs{$c}{chrom}\t$runs{$c}{start}\t$runs{$c}{end}\t$len\t$num\t$runs{$c}{tags}\n";
    print BED "$runs{$c}{chrom}\t$runs{$c}{start}\t$runs{$c}{end}\t$c\n";
}
close OUT;
close BED;
