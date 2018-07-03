#! /usr/bin/perl -w

my $sid    = $ARGV[0];
my $varlst = $ARGV[1];
my $fa_in  = $ARGV[2];
my $fa_out = $ARGV[3];

my (%name2fa);

my $infile = $fa_in;
my $name = "";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    if ($_ =~ /^>/) {
        $name = $_;
        $name =~ s/^>//;
        next;
    }
    $name2fa{$name} = $_;
}
close IN;

$infile = $varlst;
my $outfile = $fa_out;
open OUT, "> $outfile" or die "$outfile: $!";
open IN, "< $infile" or die "$infile: $!";
while(<IN>) {
    chomp;
    next if $. == 1;
    my @F = split/\t/;
    my $left = $name2fa{$F[4]};
    my $right = $name2fa{$F[5]};
    my $ref = $F[2];
    my $mut = $F[3];
    my $mut_seq = "";
    my $ref_seq = "";
    my $mut_id = "$F[0].mut";
    my $ref_id = "$F[0].ref";
    if ($F[1] eq "snv") {
        $mut_seq = $left . $mut . $right;
        $ref_seq = $left . $ref . $right;
    }elsif ($F[1] eq "ins") {
        $mut_seq = $left . $mut . $right;
        $ref_seq = $left . $right;
    }elsif ($F[1] eq "del") {
        $mut_seq = $left . $right;
        $ref_seq = $left . $ref . $right;
    }elsif ($F[1] eq "complex_indel") {
        $mut_seq = $left . $mut . $right;
        $ref_seq = $left . $ref . $right;
    }else {
        print "Wrong var type of $F[1] for $F[0].\n";
    }
    print OUT ">";
    print OUT "$mut_id\n";
    print OUT "$mut_seq\n";
    print OUT ">";
    print OUT "$ref_id\n";
    print OUT "$ref_seq\n";
}
close IN;
close OUT;

