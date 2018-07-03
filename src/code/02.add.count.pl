#! /usr/bin/perl -w

my $sid      = $ARGV[0];
my $het_wgs  = $ARGV[1];
my $geno_rna = $ARGV[2];
my $output   = $ARGV[3];

my %count = ();
my $infile = $geno_rna;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $count{$sid}{$F[1]}{ref} = $F[2];
    $count{$sid}{$F[1]}{mut} = $F[3];
    $count{$sid}{$F[1]}{cvg} = $F[2] + $F[3];
}
close IN;

$infile = $het_wgs;
my $outfile = $output;
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $outfile" or die "$outfile: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "chrom\tpos\tref\tmut\tcvg_wgs\tmut_freq_wgs\tcvg_rna\tmut_freq_rna\tref\tvar\n";
        next;
    }
    my @F = split/\t/;
    my $snv4 = "$F[0].$F[1].$F[2].$F[3]";
    my $cvg_wgs = $F[4] + $F[6];
    my $freq_wgs = sprintf("%.3f",$F[6]/$cvg_wgs);
    my $cvg_rna = $count{$sid}{$snv4}{cvg};
    if ($cvg_rna >= 10) {
        $freq_rna = sprintf("%.3f",$count{$sid}{$snv4}{mut}/$cvg_rna);
        print OUT "$F[0]\t$F[1]\t$F[2]\t$F[3]\t$cvg_wgs\t$freq_wgs\t$cvg_rna\t$freq_rna\t$count{$sid}{$snv4}{ref}\t$count{$sid}{$snv4}{mut}\n";
    }
}
close IN;
close OUT;

