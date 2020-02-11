#! /usr/bin/perl -w

my $sid         = $ARGV[0];
my $ase_result  = $ARGV[1];
my $ase_result_run  = $ARGV[2];
my $sv_result   = $ARGV[3];
my $output      = $ARGV[4];
my $win         = $ARGV[5];
my $refgene     = $ARGV[6];

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

$infile = $sv_result;
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $output" or die "$output: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "gsym_left\tdist_left\tgsym_right\tdist_right\t$_\n";
        next;
    }
    my @F = split/\t/;
    my $record = 0;
    my %left = ();
    my %right = ();
### check breakpoint on left.
    my $chrom = $F[0];
    unless ($chrom =~ /^chr/) {
        $chrom = "chr" . $chrom;
    }
    my $pos = $F[1];
    if ($chr2g{$chrom}) {
        my @g = keys %{$chr2g{$chrom}};
        for my $g (@g) {
            if ($pos >= $genes{$g}{start}-$win and $pos <= $genes{$g}{end}+$win) {
                my $dist = 0;
                $record = 1;
                if ($genes{$g}{strand} eq "+") {
                    $dist = $pos - $genes{$g}{start};
                }else {
                    $dist = $pos - $genes{$g}{end};
                }
                $left{$genes{$g}{gsym}} = $dist;
            }
        }
    }
### check breakpoint on right.
    $chrom = $F[3];
    unless ($chrom =~ /^chr/) {
        $chrom = "chr" . $chrom;
    }
    $pos = $F[4];
    if ($chr2g{$chrom}) {
        my @g = keys %{$chr2g{$chrom}};
        for my $g (@g) {
            if ($pos >= $genes{$g}{start}-$win and $pos <= $genes{$g}{end}+$win) {
                my $dist = 0;
                $record = 1;
                if ($genes{$g}{strand} eq "+") {
                    $dist = $pos - $genes{$g}{start};
                }else {
                    $dist = $pos - $genes{$g}{end};
                }
                $right{$genes{$g}{gsym}} = $dist;
            }
        }
    }
    next unless $record;
    my $left_gsym = "";
    my $left_dist = "";
    my $right_gsym = "";
    my $right_dist = "";
    for my $l (sort keys %left) {
        next unless $l;
        $left_gsym .= "$l,";
        $left_dist .= "$left{$l},";
    }
    for my $r (sort keys %right) {
        next unless $r;
        $right_gsym .= "$r,";
        $right_dist .= "$right{$r},";
    }
    $left_gsym =~ s/\,$//;
    $left_dist =~ s/\,$//;
    $right_gsym =~ s/\,$//;
    $right_dist =~ s/\,$//;
    print OUT "$left_gsym\t$left_dist\t$right_gsym\t$right_dist\t$_\n";
}
close IN;
close OUT;
