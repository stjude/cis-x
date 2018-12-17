#! /usr/bin/perl -w

my $sid         = $ARGV[0];
my $ase_result  = $ARGV[1];
my $cnv_result  = $ARGV[2];
my $output      = $ARGV[3];
my $win         = $ARGV[4];
my $size        = $ARGV[5];

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

$infile = $cnv_result;
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $output" or die "$output: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "gsym\tdist\t$_\n";
        next;
    }
    my @F = split/\t/;
    my $length = $F[2] - $F[1];
    next unless $length <= $size;
    my %target = ();
### check for intersection.
    my $chrom = $F[0];
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

