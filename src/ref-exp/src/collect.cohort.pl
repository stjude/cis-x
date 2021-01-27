#! /usr/bin/perl -w

my (%sid,%dat,%gene,%g2fpkm,%checksid);

my $config  = $ARGV[0];
my $workdir = $ARGV[1];
my $expfile = $ARGV[2];

my $infile = $config;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    $sid{$F[0]} = 1;
}
close IN;

my %col2sid;
$infile = $expfile;
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    my @F = split/\t/;
    if ($. == 1) {
        for my $i (7 .. $#F) {
            $col2sid{$i} = $F[$i];
            $checksid{$F[$i]} = 1;
        }
        next;
    }
    $gene{$F[1]} = 1;
    for my $i (7 .. $#F) {
        $g2fpkm{$F[1]}{$col2sid{$i}} = $F[$i];
    }
}
close IN;

my $NoneExistSID = 0;
for my $s (sort keys %sid) {
    unless ($checksid{$s}) {
        print "$s not exist in the exp matrix $expfile.\n";
        $NoneExistSID = 1;
    }
}

if ($NoneExistSID == 1) {
    die("Error: SID printed above not exist in the expression matrix.");
}

for my $sid (sort keys %sid) {
    my $infile = "$workdir/$sid/working_space/$sid.ase.gene.model.fdr.txt";
    if (! -e $infile) {
        print "$infile not exist.\n";
        next;
    }
    open IN, "< $infile" or die "$infile: $!";
    while(<IN>) {
        chomp;
        next if $. == 1;
        my @F = split/\t/;
        next unless $g2fpkm{$F[1]};
        if ($F[22]<0.05 and $F[19]>=0.3) {
            $dat{$F[1]}{ase}{sid} .= "$sid,";
            $dat{$F[1]}{ase}{fpkm} .= "$g2fpkm{$F[1]}{$sid},";
        }elsif ($F[22] >= 0.05 and $F[9] == 0) { ### criteria updated on Dec 27, 2017.
            $dat{$F[1]}{bi}{sid} .= "$sid,";
            $dat{$F[1]}{bi}{fpkm} .= "$g2fpkm{$F[1]}{$sid},";
        }else {
            1;
        }
    }
    close IN;
}

my $outfile = "$workdir/cis-X.refexp.step2.collect.txt";
open OUT, "> $outfile" or die "$outfile: $!";
print OUT "gene\tpresent.TARGET\tnum.ase.samples\tase.samples\tfpkm.ase.samples\tnum.bi.samples\tbi.samples\tfpkm.bi.samples\n";
for my $g (sort keys %dat) {
    my $present = 0;
    my $ase_count = 0;
    my $bi_count = 0;
    my $ase_sid = "";
    my $bi_sid = "";
    my $fpkm_ase = "";
    my $fpkm_bi = "";
    $present = 1 if $gene{$g};
    if ($dat{$g}{ase}) {
        $ase_sid = $dat{$g}{ase}{sid};
        $fpkm_ase = $dat{$g}{ase}{fpkm};
        $ase_sid =~ s/\,$//;
        $fpkm_ase =~ s/\,$//;
        my @s_a = split(/,/,$ase_sid);
        $ase_count = scalar(@s_a);
    }
    if ($dat{$g}{bi}) {
        $bi_sid = $dat{$g}{bi}{sid};
        $fpkm_bi = $dat{$g}{bi}{fpkm};
        $bi_sid =~ s/\,$//;
        $fpkm_bi =~ s/\,$//;
        my @s_b = split(/,/,$bi_sid);
        $bi_count = scalar(@s_b);
    }
    print OUT "$g\t$present\t$ase_count\t$ase_sid\t$fpkm_ase\t$bi_count\t$bi_sid\t$fpkm_bi\n";
}
close OUT;

