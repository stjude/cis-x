#! /usr/bin/perl -w

my $sid         = $ARGV[0];
my $ase_result  = $ARGV[1];
my $sv_result   = $ARGV[2];
my $output      = $ARGV[3];
my $win         = $ARGV[4];

my (%genes,%chr2g);

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
}
close IN;

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

