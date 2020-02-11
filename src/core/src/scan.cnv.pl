#! /usr/bin/perl -w

my $sid             = $ARGV[0];
my $ase_result      = $ARGV[1];
my $ase_result_run  = $ARGV[2];
my $cnv_result      = $ARGV[3];
my $output          = $ARGV[4];
my $win             = $ARGV[5];
my $size            = $ARGV[6];
my $refgene         = $ARGV[7];
my $perc_overlap    = $ARGV[8];

my (%genes,%chr2g,%candidates,%g2query);

my $infile = $ase_result;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $genes{$F[0]}{gsym}   = $F[1];
    $genes{$F[0]}{chrom}  = $F[2];
    $genes{$F[0]}{strand} = $F[3];
    $genes{$F[0]}{start}  = $F[4];
    $genes{$F[0]}{end}    = $F[5];
    $chr2g{$F[2]}{$F[0]}  = 1;
    $candidates{$F[1]}    = 1;
}
close IN;

$infile = $ase_result_run;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    if ($F[8]) {
        my @G = split(/,/,$F[8]);
        for my $g (@G) {
            next if $candidates{$g};
            $g2query{$g}{tag} = 1;
        }
    }
}
close IN;

$infile = $refgene;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    if ($g2query{$F[3]}) {
        my $len = $F[2] - $F[1];
        if ($g2query{$F[3]}{tag} == 1 or ($len > $g2query{$F[3]}{len})) {
            $g2query{$F[3]}{acc}    = $F[4];
            $g2query{$F[3]}{chrom}  = $F[0];
            $g2query{$F[3]}{strand} = $F[5];
            $g2query{$F[3]}{start}  = $F[1];
            $g2query{$F[3]}{end}    = $F[2];
            $g2query{$F[3]}{len}    = $len;
            $g2query{$F[3]}{tag}    = 2;
        }else {
            1;
        }
    }
}
close IN;

for my $g (sort keys %g2query) {
    if ($g2query{$g}{tag} == 1) {
        print "Error, $g not annotated.\n";
    }else {
        $candidates{$g} = 1;
        my $acc = $g2query{$g}{acc};
        $genes{$acc}{gsym}   = $g;
        $genes{$acc}{chrom}  = $g2query{$g}{chrom};
        $genes{$acc}{strand} = $g2query{$g}{strand};
        $genes{$acc}{start}  = $g2query{$g}{start};
        $genes{$acc}{end}    = $g2query{$g}{end};
        $chr2g{$g2query{$g}{chrom}}{$acc} = 1;
    }
}

$infile = $cnv_result;
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $output" or die "$output: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "gsym\tdist\t$_\n";
        next;
    }
    my $record = 0;
    my @F = split/\t/;
    my $length = $F[2] - $F[1];
    next unless $length <= $size;
    my %target = ();
### check for intersection.
    my $chrom = $F[0];
    unless ($chrom =~ /^chr/) {
        $chrom = "chr" . $chrom;
    }
    my $pos_left = $F[1];
    my $pos_right = $F[2];
#    my $left_pos = $F[1];
#    my $right_pos = $F[2];
    if ($chr2g{$chrom}) {
        my @g = keys %{$chr2g{$chrom}};
        for my $g (@g) {
            if ($pos_left > $genes{$g}{end}+$win) {
                1;
            }elsif ($pos_right < $genes{$g}{start}-$win) {
                1;
            }else {
                my $overlap = 0;
                my $glen = $genes{$g}{end} - $genes{$g}{start};
                if ($pos_left <= $genes{$g}{start} and $pos_right >= $genes{$g}{start}) {
                    if ($pos_right < $genes{$g}{end}) {
                        $overlap = $pos_right - $genes{$g}{start};
                    }else {
                        $overlap = $genes{$g}{end} - $genes{$g}{start};
                    }
                }elsif ($pos_left >= $genes{$g}{start} and $pos_left <= $genes{$g}{end}) {
                    if ($pos_right <= $genes{$g}{end}) {
                        $overlap = $pos_right - $pos_left;
                    }else {
                        $overlap = $genes{$g}{end} - $pos_left;
                    }
                }
                if ($overlap/$glen < $perc_overlap) {
                    $record = 1;
                    my $dist = 0;
                    if ($genes{$g}{strand} eq "+") {
                        $dist = $pos_left - $genes{$g}{start};
                        $dist = $pos_right - $genes{$g}{start} if (abs($pos_right - $genes{$g}{start}) < abs($pos_left - $genes{$g}{start}));
                    }else {
                        $dist = $pos_left - $genes{$g}{end};
                        $dist = $pos_right - $genes{$g}{end} if (abs($pos_right - $genes{$g}{end}) < abs($pos_left - $genes{$g}{end}));
                    }
                    $target{$genes{$g}{gsym}} = $dist;
                }
            }
        }
    }
    next unless $record;
    my $target_gsym = "";
    my $target_dist = "";
    for my $t (sort keys %target) {
        next unless $t;
        $target_gsym .= "$t,";
        $target_dist .= "$target{$t},";
    }
    $target_gsym =~ s/\,$//;
    $target_dist =~ s/\,$//;
    print OUT "$target_gsym\t$target_dist\t$_\n";
}
close IN;
close OUT;

