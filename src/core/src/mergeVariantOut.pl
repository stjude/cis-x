#! /usr/bin/perl -w

my $workdir = $ARGV[0];
my $outfile = $ARGV[1];
my $chr_string = $ARGV[2];

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
        if ($chr_string eq "TRUE") {
            print OUT "$_\n";
        }else {
            my @F = split/\t/;
            my $snv4 = "chr" . $F[1];
            print OUT "$F[0]\t$snv4\t$F[2]\t$F[3]\n";
        }
    }
    close IN;
}
close OUT;

