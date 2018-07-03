#! /usr/bin/perl -w
### Only the longest transcript was used.

my $infile = $ARGV[0];
my $outfile = $ARGV[1];

my $head = "";
my %dat = ();
my %g2len = ();

open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        $head = $_;
        next;
    }
    my @F = split/\t/;
    next unless $F[8];
    my $len = $F[5] - $F[4];
    if ($dat{$F[1]}) {
        if ($len > $g2len{$F[1]}) {
            $dat{$F[1]} = $_;
            $g2len{$F[1]} = $len;
        }else {
            1;
        }
    }else {
        $dat{$F[1]} = $_;
        $g2len{$F[1]} = $len;
    }
}
close IN;

open OUT, "> $outfile" or die "$outfile: $!";
print OUT "$head\n";
for my $g (sort keys %dat) {
    print OUT "$dat{$g}\n";
}
close OUT;

