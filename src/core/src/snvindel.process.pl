#! /usr/bin/perl -w

my $sid            = $ARGV[0];
my $fimo_pred      = $ARGV[1];
my $fimo_acc2gsym  = $ARGV[2];
my $snvindel_input = $ARGV[3];
my $fpkm_res       = $ARGV[4];
my $tf_fpkm_thresh = $ARGV[5];
my $output         = $ARGV[6];
my $roadmap_enh    = $ARGV[7];
my $roadmap_pro    = $ARGV[8];
my $roadmap_dya    = $ARGV[9];

my (%tf2gsym,%tflst,%g2fpkm,%var,%var2tf,%chr2var);

my $infile = $fimo_acc2gsym;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    next if $F[0] =~ /RETRACTED/;
#    $tf2gsym{$F[0]} = $F[2];
#    $tflst{$F[2]} = 1;
    $tf2gsym{$F[0]} = $F[1];
    $tflst{$F[1]} = 1;
}
close IN;

### coded with current format, may need improve.
$infile = $fpkm_res;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    next unless $tflst{$F[1]};
    if ($g2fpkm{$F[1]}) {
        if ($g2fpkm{$F[1]} < $F[7]) {
            $g2fpkm{$F[1]} = $F[7];
        }
    }else {
        $g2fpkm{$F[1]} = $F[7];
    }
}
close IN;

$infile = $snvindel_input;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my @f = split(/\./,$F[0]);
    $var{$F[0]}{target} = $F[6];
    $var{$F[0]}{dist}   = $F[7];
    $var{$F[0]}{type}   = $F[1];
    $var{$F[0]}{start}  = $F[8];
    $var{$F[0]}{len}    = $F[9];
    $var{$F[0]}{mut}    = $F[3];
    $var{$F[0]}{ref}    = $F[2];
    $var{$F[0]}{chrom}  = $f[0];
    $var{$F[0]}{pos}    = $f[1];
    $chr2var{$f[0]}{$F[0]} = 1;
}
close IN;

open IN, "< $roadmap_enh" or die "$roadmap_enh: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    for my $var (sort keys %{$chr2var{$F[0]}}) {
        if ($var{$var}{pos} >= $F[1] and $var{$var}{pos} <= $F[2]) {
            $var{$var}{enh}{$F[7]} = 1;
        }
    }
}
close IN;

open IN, "< $roadmap_pro" or die "$roadmap_pro: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    for my $var (sort keys %{$chr2var{$F[0]}}) {
        if ($var{$var}{pos} >= $F[1] and $var{$var}{pos} <= $F[2]) {
            $var{$var}{pro}{$F[7]} = 1;
        }
    }
}
close IN;

open IN, "< $roadmap_dya" or die "$roadmap_dya: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    for my $var (sort keys %{$chr2var{$F[0]}}) {
        if ($var{$var}{pos} >= $F[1] and $var{$var}{pos} <= $F[2]) {
            $var{$var}{dya}{$F[7]} = 1;
        }
    }
}
close IN;

my @var = sort keys %var;
my $varnum = scalar(@var);
if ($varnum == 0) {
    open OUT, "> $output" or die "$output: $!";
    print OUT "chrom\tpos\tref\tmut\ttarget\tdist\ttf\tEpiRoadmap_enhancer\tEpiRoadmap_promoter\tEpiRoadmap_dyadic\n";
    close OUT;
}else {
    $infile = $fimo_pred;
    open IN, "< $infile" or die "$infile: $!";
    while(<IN>) {
        chomp;
        next if $. == 1;
        my @F = split/\t/;
        my $tf = "";
        my $fpkm = 0;
        if ($tf2gsym{$F[0]}) {
            $tf = $tf2gsym{$F[0]};
        }
        next unless $tf;
        if ($tf eq "MYBL1" or $tf eq "MYBL2") { ### 2019-03-11, The motif for MYB, MYBL1/2 are very similar in this version of db. May update in later version.
            $tf = "MYB";
        }
        if ($g2fpkm{$tf}) {
            $fpkm = $g2fpkm{$tf};
        }
        next unless $fpkm > $tf_fpkm_thresh;
        my $mut = 0;
        my $ref = 0;
        my @f = split(/\./,$F[1]);
        my $var = "$f[0].$f[1].$f[2].$f[3]";
        my $type = $var{$var}{type};
        my $pos = $var{$var}{start};
        my $len = $var{$var}{len};
        if ($type eq "snv") {
            if ($pos >= $F[2] and $pos <= $F[3]) {
                if ($f[4] eq "mut") {
                    $mut = 1;
                }elsif ($f[4] eq "ref") {
                    $ref = 1;
                }else {
                    print "Wrong type for $F[1].\n";
                }
            }
        }elsif ($type eq "ins") {
            if ($f[4] eq "mut") {
                my $start = $pos;
                my $end = $pos + $len - 1;
                if ($start > $F[3]) {
                    1;
                }elsif ($start >= $F[2]) {
                    $mut = 1;
                }elsif ($end >= $F[2]) {
                    $mut = 1;
                }else {
                    1;
                }
            }elsif ($f[4] eq "ref") {
                if ($pos >= $F[2] and $pos <= $F[3]) {
                    $ref = 1;
                }
            }else {
                print "Wrong type for $F[1].\n";
            }
        }elsif ($type eq "del") {
            if ($f[4] eq "mut") {
                if ($pos >= $F[2] and $pos <= $F[3]) {
                    $mut = 1;
                }
            }elsif ($f[4] eq "ref") {
                my $start = $pos;
                my $end = $pos + $len - 1;
                if ($start > $F[3]) {
                    1;
                }elsif ($start >= $F[2]) {
                    $ref = 1;
                }elsif ($end >= $F[2]) {
                    $ref = 1;
                }else {
                    1;
                }
            }else {
                print "Wrong type for $F[1].\n";
            }
        }elsif ($type eq "complex_indel") {
            if ($f[4] eq "mut") {
                my @mutseq = split(//,$var{$var}{mut});
                my $seqlen = scalar(@mutseq);
                my $start = $pos;
                my $end = $pos + $seqlen - 1;
                if ($start > $F[3]) {
                    1;
                }elsif ($start >= $F[2]) {
                    $mut = 1;
                }elsif ($end >= $F[2]) {
                    $mut = 1;
                }else {
                    1;
                }
            }elsif ($f[4] eq "ref") {
                my @refseq = split(//,$var{$var}{ref});
                my $seqlen = scalar(@refseq);
                my $start = $pos;
                my $end = $pos + $seqlen - 1;
                if ($start > $F[3]) {
                    1;
                }elsif ($start >= $F[2]) {
                    $ref = 1;
                }elsif ($end >= $F[2]) {
                    $ref = 1;
                }else {
                    1;
                }
            }else {
                print "Wrong type for $F[1].\n";
            }
        }else {
            print "Wrong type for $type.\n";
        }
        if ($f[4] eq "mut") {
            $var{$var}{tf}{$tf}{mut} = $mut;
        }elsif ($f[4] eq "ref") {
            $var{$var}{tf}{$tf}{ref} = $ref;
        }else {
            print "Wrong type for $F[1].\n";
        }
    }
    close IN;

    open OUT, "> $output" or die "$output: $!";
    print OUT "chrom\tpos\tref\tmut\ttype\ttarget\tdist\ttf\tEpiRoadmap_enhancer\tEpiRoadmap_promoter\tEpiRoadmap_dyadic\n";
    for my $var (sort keys %var) {
        my $pred_tf = "";
        for my $tf (sort keys %{$var{$var}{tf}}) {
            my $ref = 0;
            my $mut = 0;
            $ref = $var{$var}{tf}{$tf}{ref} if $var{$var}{tf}{$tf}{ref};
            $mut = $var{$var}{tf}{$tf}{mut} if $var{$var}{tf}{$tf}{mut};
            if ($mut == 1 and $ref == 0) {
                $pred_tf .= "$tf,";
            }
        }
        if ($pred_tf) {
            my @var = split(/\./,$var);
            $pred_tf =~ s/\,$//;
            my $enh = "";
            my $pro = "";
            my $dya = "";
            if ($var{$var}{enh}) {
                my @enh = sort keys %{$var{$var}{enh}};
                $enh = join(',',@enh);
            }
            if ($var{$var}{pro}) {
                my @pro = sort keys %{$var{$var}{pro}};
                $pro = join(',',@pro);
            }
            if ($var{$var}{dya}) {
                my @dya = sort keys %{$var{$var}{dya}};
                $dya = join(',',@dya);
            }
            print OUT "$var[0]\t$var[1]\t$var[2]\t$var[3]\t$var{$var}{type}\t$var{$var}{target}\t$var{$var}{dist}\t$pred_tf\t$enh\t$pro\t$dya\n";
        }
    }
    close OUT;
}

