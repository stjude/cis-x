#! /usr/bin/perl -w

my $codedir = $ARGV[0];
my $workdir = $ARGV[1];

my (%gene,%imprint);

my $infile = "$codedir/ref/hg19_refGene";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my $g = $F[12];
    $gene{$g}{chrom} = $F[2];
}
close IN;

$infile = "$codedir/ref/ImprintGenes.txt";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $imprint{$F[0]} = $F[3];
}
close IN;

$infile = "$workdir/cis-X.refexp.step2.collect.txt";
my $outfile = "$workdir/cis-X.refexp.step2.collect.filtered.txt";
open IN, "< $infile" or die "$infile: $!";
open OUT, "> $outfile" or die "$outfile: $!";
while(<IN>) {
    chomp;
    if ($. == 1) {
        print OUT "$_\tchrom\timprinting\tase_fpkm_max\tase_fpkm_gt1_count\tbi_fpkm_max\tbi_fpkm_gt1_count\n";
        next;   
    }
    my @F = split/\t/;
    next unless $F[1] == 1;
    my $g = $F[0];
    my $ase_max = "na";
    my $bi_max = "na";
    my $ase_count = 0;
    my $bi_count = 0;
    if ($F[2] > 0) {
        my @ase = split(/,/,$F[4]);
        $ase_max = $ase[0];
        for my $i (0 .. $#ase) {
            if ($ase[$i] > $ase_max) {
                $ase_max = $ase[$i];
            }
            if ($ase[$i] >= 1) {
                $ase_count++;
            }
        }
    }
    if ($F[5] > 0) {
        my @bi  = split(/,/,$F[7]);
        $bi_max = $bi[0];
        for my $j (0 .. $#bi) {
            if ($bi[$j] > $bi_max) {
                $bi_max = $bi[$j];
            }
            if ($bi[$j] >= 1) {
                $bi_count++;
            }
        }
    }
    my $imprint = "";
    if ($imprint{$g}) {
        $imprint = $imprint{$g};
    }
    my $chrom = $gene{$g}{chrom};
    next if $chrom =~ /hap/;
    print OUT "$_\t$chrom\t$imprint\t$ase_max\t$ase_count\t$bi_max\t$bi_count\n";
}
close IN;
close OUT;

