#! /usr/bin/perl -w

my $sid           = $ARGV[0];
my $snvindel_in   = $ARGV[1];
my $ase_result    = $ARGV[2];
my $ase_result_run  = $ARGV[3];
my $sv_result     = $ARGV[4];
my $cna_result    = $ARGV[5];
my $tad_ref       = $ARGV[6];
my $snvindel_list = $ARGV[7];
my $seqlist       = $ARGV[8];
my $snvindel_win  = $ARGV[9];
my $refgene       = $ARGV[10];

my (%genes,%solved,%chr2g,%g2pro,%snvindel,%tad,%g2query);

my $infile = $tad_ref;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    my $id = "$F[0].$F[1].$F[2]";
    $tad{$F[0]}{$id}{start} = $F[1];
    $tad{$F[0]}{$id}{end}   = $F[2];
    $tad{$F[0]}{$id}{source} = "hESC";
}
close IN;

$infile = $ase_result;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $genes{$F[1]}{gsym}   = $F[1];
    $genes{$F[1]}{chrom}  = $F[2];
    $genes{$F[1]}{strand} = $F[3];
    $genes{$F[1]}{start}  = $F[4];
    $genes{$F[1]}{end}    = $F[5];
    $chr2g{$F[2]}{$F[1]}  = 1;
    if ($F[3] eq "+") {
        $g2pro{$F[1]}{start} = $F[4] - 2000;
        $g2pro{$F[1]}{end}   = $F[4] + 200;
    }elsif ($F[3] eq "-") {
        $g2pro{$F[1]}{start} = $F[5] - 200;
        $g2pro{$F[1]}{end}   = $F[5] + 2000;
    }
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
            next if $genes{$g};
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
        $genes{$g}{gsym}   = $g;
        $genes{$g}{chrom}  = $g2query{$g}{chrom};
        $genes{$g}{strand} = $g2query{$g}{strand};
        $genes{$g}{start}  = $g2query{$g}{start};
        $genes{$g}{end}    = $g2query{$g}{end};
        $chr2g{$g2query{$g}{chrom}}{$g} = 1;
        if ($g2query{$g}{strand} eq "+") {
            $g2pro{$g}{start} = $g2query{$g}{start} - 2000;
            $g2pro{$g}{end}   = $g2query{$g}{start} + 200;
        }elsif ($g2query{$g}{strand} eq "-") {
            $g2pro{$g}{start} = $g2query{$g}{end} - 200;
            $g2pro{$g}{end}   = $g2query{$g}{end} + 2000;
        }
    }
}

$infile = $sv_result;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    if ($F[0]) {
        my @g = split(/,/,$F[0]);
        for my $g (@g) {
            $solved{$g} = 1;
        }
    }
    if ($F[1]) {
        my @g = split(/,/,$F[1]);
        for my $g (@g) {
            $solved{$g} = 1;
        }
    }
}
close IN;

$infile = $cna_result;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    if ($F[0]) {
        my @g = split(/,/,$F[0]);
        for my $g (@g) {
            $solved{$g} = 1;
        }
    }
}
close IN;

$infile = $snvindel_in;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my $chrom = $F[0];
    unless ($chrom =~ /^chr/) {
        $chrom = "chr" . $chrom;
    }
    my $pos = $F[1];
    my $target = "";
    my $dist_o = "";
    my @g = sort keys %{$chr2g{$chrom}};
    ### filter TAD.
    for my $tad (sort keys %{$tad{$chrom}}) {
        if ($pos <= $tad{$chrom}{$tad}{end} and $pos >= $tad{$chrom}{$tad}{start}) {
            for my $g (@g) {
                next if $solved{$g};
                my $overlap = 0;
                if ($g2pro{$g}) {
                    if ($g2pro{$g}{start} > $tad{$chrom}{$tad}{end}) {
                        1;
                    }elsif ($g2pro{$g}{start} >= $tad{$chrom}{$tad}{start}) {
                        $overlap = 1;
                    }elsif ($g2pro{$g}{end} >= $tad{$chrom}{$tad}{start}) {
                        $overlap = 1;
                    }else {
                        1;
                    }
                }else {
                    print "No promoter info for $g.\n";
                }
                if ($overlap == 1) {
                    ### require distance between target gene tss less than $snvindel_win.
                    my $dist = abs($pos - $genes{$g}{start});
                    if ($genes{$g}{strand} eq "-") {
                        $dist = abs($pos - $genes{$g}{end});
                    }
                    if ($dist <= $snvindel_win) {
                        $target .= "$g,";
                        $dist_o .= "$dist,";
                    }
                }
            }
        }
    }
    if ($target) {
        $target =~ s/\,$//;
        $dist_o =~ s/\,$//;
        my $snv4 = "$chrom.$F[1].$F[2].$F[3]";
        $snvindel{$snv4}{target} = $target;
        $snvindel{$snv4}{type}   = $F[4];
        $snvindel{$snv4}{dist}   = $dist_o;
    }
}
close IN;

my $outfile = $snvindel_list;
my $seq_out = $seqlist;
open OUT, "> $outfile" or die "$outfile: $!";
open SEQLST, "> $seq_out" or die "$seq_out: $!";
print OUT "snv4\ttype\tref\tmut\tleft_name\tright_name\ttarget\tdist\tstart\tlength\n";
for my $snv4 (sort keys %snvindel) {
    my @s = split(/\./,$snv4);
    my $chrom  = $s[0];
    my $pos    = $s[1];
    my $ref    = $s[2];
    my $mut    = $s[3];
    my $target = $snvindel{$snv4}{target};
    my $type   = $snvindel{$snv4}{type};
    my $dist   = $snvindel{$snv4}{dist};
    my $left   = "";
    my $right  = "";
    my $start  = 21;
    my $length = 1;
    if ($type eq "snv") {
        $start_l = $pos - 1 - 20;
        $end_l   = $pos - 1;
        $start_r = $pos - 1 + 1;
        $end_r   = $pos - 1 + 1 + 20;
        $left    = $chrom . ":" . $start_l . "-" . $end_l;
        $right   = $chrom . ":" . $start_r . "-" . $end_r;
    }else {
        if ($ref eq "-") {
            $type = "ins";
            $start_l = $pos - 1 - 20;
            $end_l   = $pos - 1;
            $start_r = $pos - 1;
            $end_r   = $pos - 1 + 20;
            $left    = $chrom . ":" . $start_l . "-" . $end_l;
            $right   = $chrom . ":" . $start_r . "-" . $end_r;
            my @seq = split(//,$mut);
            $length = scalar(@seq);
        }elsif ($mut eq "-") {
            $type = "del";
            my @seq = split(//,$ref);
            my $len = scalar(@seq);
            $length = $len;
            $start_l = $pos - 1 - 20;
            $end_l   = $pos - 1;
            $start_r = $pos - 1 + $len;
            $end_r   = $pos - 1 + $len + 20;
            $left    = $chrom . ":" . $start_l . "-" . $end_l;
            $right   = $chrom . ":" . $start_r . "-" . $end_r;
        }else {
            $type = "complex_indel";
            my @seq = split(//,$ref);
            my $len = scalar(@seq);
            $start_l = $pos - 1 - 20;
            $end_l   = $pos - 1;
            $start_r = $pos - 1 + $len;
            $end_r   = $pos - 1 + $len + 20;
            $left    = $chrom . ":" . $start_l . "-" . $end_l;
            $right   = $chrom . ":" . $start_r . "-" . $end_r;
        }
    }
    $left =~ s/^chr//;
    $right =~ s/^chr//;
    print OUT "$snv4\t$type\t$ref\t$mut\t$left\t$right\t$target\t$dist\t$start\t$length\n";
    print SEQLST "$left\n$right\n";
}
close OUT;
close SEQLST;
