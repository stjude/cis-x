#! /usr/bin/perl -w

my $workdir = $ARGV[0];
my $outfile = $ARGV[1];

open OUT, "> $outfile" or die "$outfile: $!";
for my $i (1 .. 22) {
    my $infile = "$workdir/matrix_chr" . $i . "_simple.tab";
    if (! -e $infile) {
        print "$infile not exist.\n";
        next;
    }
    open IN, "< $infile" or die "$infile: $!";
    while(<IN>) {
        chomp;
        if ($. == 1) {
            if ($i == 1) {
                print OUT "$_\n";
            }
            next;
        }
        print OUT "$_\n";
    }
    close IN;
}
close OUT;

