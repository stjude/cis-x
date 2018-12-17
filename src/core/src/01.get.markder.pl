#! /usr/bin/perl -w
my $sid       = $ARGV[0];
my $high20    = $ARGV[1];  ### high20 from WGS.
my $cnvloh_in = $ARGV[2];
my $snv4_out  = $ARGV[3];
my $het_out   = $ARGV[4];
my $bad_lst   = $ARGV[5];
my $covg      = $ARGV[6];

my $upper   = 0.7;
my $lower   = 0.3;
#my $covg    = 10;
my %badlst  = ();
my %chrom   = ();
my %col2snv = ();
my %cnvloh  = ();

for my $i (1 .. 22) {
    my $c = "chr" . $i;
    $chrom{$c} = 1;
}

my $infile = $bad_lst;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    $badlst{$_} = 1;
}
close IN;

$infile = $cnvloh_in;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my $chr = $F[0];
    my $id = "$chr.$F[1].$F[2]";
    $cnvloh{chrom}{$chr}{$id}   = 1;
    $cnvloh{region}{$id}{chr}   = $chr;
    $cnvloh{region}{$id}{start} = $F[1];
    $cnvloh{region}{$id}{end}   = $F[2];
}
close IN;

#my $outfile = "$sid.heterozygous.txt";
my $outfile = $het_out;
open OUT, "> $outfile" or die "$outfile: $!";
open SNV4OUT, "> $snv4_out" or die "$snv4_out: $!";
print OUT "chrom\tposition\tref\tmut\tref_T\tref_G\tmut_T\tmut_G\tcnvlohTag\n";
open H20, "< $high20" or die "$high20: $!";
while(<H20>) {
    chomp;
    my @F = split/\t/;
    if ($. == 1) {
        for my $i (0 .. $#F) {
            if ($F[$i] eq "Chr") {
                $col2snv{chr} = $i;
            }
            if ($F[$i] eq "Pos") {
                $col2snv{pos} = $i;
            }
            if ($F[$i] eq "reference_tumor_count") {
                $col2snv{ref_tum_num} = $i;
            }
            if ($F[$i] eq "alternative_tumor_count") {
                $col2snv{mut_tum_num} = $i;
            }
            if ($F[$i] eq "Chr_Allele") {
                $col2snv{ref_g} = $i;
            }
            if ($F[$i] eq "Alternative_Allele") {
                $col2snv{mut_g} = $i;
            }
            if ($F[$i] eq "reference_normal_count") {
                $col2snv{ref_norm_num} = $i;
            }
            if ($F[$i] eq "alternative_normal_count") {
                $col2snv{mut_norm_num} = $i;
            }
        }
        next;
    }
#    next unless $F[5] eq "SNP";
    next unless ($F[$col2snv{ref_g}] =~ /[ATCG]/ and $F[$col2snv{mut_g}] =~ /[ATCG]/); ### make sure only SNP was included.
    next unless $chrom{$F[$col2snv{chr}]};
    my $cvg = $F[$col2snv{ref_tum_num}] + $F[$col2snv{mut_tum_num}];
    next unless $cvg >= $covg;
    my $snv4 = "$F[$col2snv{chr}].$F[$col2snv{pos}].$F[$col2snv{ref_g}].$F[$col2snv{mut_g}]";
    next if $badlst{$snv4};  ## drop the BAD markers.

    ### filter markers in cnv-loh regions
    ### updated 2018-12-04. no filter at this stage, give a tag instead indicating if a marker sits inside cnvloh region.
#    my $hit = 0;
    my $tag = "diploid";
    for my $id (sort keys %{$cnvloh{chrom}{$F[$col2snv{chr}]}}) {
        if ($F[$col2snv{pos}] >= $cnvloh{region}{$id}{start} and $F[$col2snv{pos}] <= $cnvloh{region}{$id}{end}) {
#            $hit = 1;
            $tag = "cnvloh";
        }
    }
#    next if $hit == 1;
    ### end of cnv-loh filter

    my $maf = $F[$col2snv{mut_tum_num}] / $cvg;
    if ($lower <= $maf and $maf <= $upper) {
        print OUT "$F[$col2snv{chr}]\t$F[$col2snv{pos}]\t$F[$col2snv{ref_g}]\t$F[$col2snv{mut_g}]\t$F[$col2snv{ref_tum_num}]\t$F[$col2snv{ref_norm_num}]\t$F[$col2snv{mut_tum_num}]\t$F[$col2snv{mut_norm_num}]\t$tag\n";
        print SNV4OUT "$snv4\n";
    }
}
close H20;
close OUT;
close SNV4OUT;

