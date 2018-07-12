#!/usr/bin/perl -w
use strict;

my $input = $ARGV[0];
my $GTF   = $ARGV[1];

my $flst = "file.lst";
my $fbase = "RNAseq_GENCODEv19";

system "echo $input > $flst";

open(IN, "<$flst");
my @flst = <IN>;
close (IN);
chomp @flst;

my %sum = ();
my %count = ();
my @samples = ();
foreach my $f (@flst) {
  my @a = split(/\//, $f);
  my $nm = $a[$#a];
  $nm =~ s/counts//g;
  $nm =~ s/^\.//g;
  $nm =~ s/\.txt//g;
  push @samples, $nm;
  open(IN, "<$f");
  while (my $line = <IN>) {
    chomp $line;
    my @a = split(/\t/, $line);
    if ($a[0] eq '__no_feature') {$count{$nm}{'no_feature'} = $a[1]; last;}
    $count{$nm}{$a[0]} = $a[1];
    $sum{$nm} += $a[1];
  }
  close (IN);
}

open(OUT1, ">${fbase}_mRNA_count.txt");
open(OUT2, ">${fbase}_lincRNA_count.txt");
open(OUT3, ">${fbase}_antisense_count.txt");
open(OUT, ">${fbase}_all_count.txt");
print OUT1 "GeneID\tGeneName\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
print OUT2 "GeneID\tGeneName\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
print OUT3 "GeneID\tGeneName\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
print OUT "GeneID\tGeneName\tType\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
open(FPM1, ">${fbase}_mRNA_fpkm.txt");
open(FPM2, ">${fbase}_lincRNA_fpkm.txt");
open(FPM3, ">${fbase}_antisense_fpkm.txt");
open(FPM, ">${fbase}_all_fpkm.txt");
print FPM1 "GeneID\tGeneName\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
print FPM2 "GeneID\tGeneName\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
print FPM3 "GeneID\tGeneName\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
print FPM "GeneID\tGeneName\tType\tStatus\tChr\tStart\tEnd\t", join("\t", @samples), "\n";
open(IN, "< $GTF");   ### for v19.
while (my $line = <IN>) {
  chomp $line;
  my @a = split(/\t/, $line);
  my $ip = 0;
  foreach my $s (@samples) {
    if ($count{$s}{$a[0]} > 0) {$ip = 1; last;}
  }
  if ($ip == 0) {next;}
  my @tmp1 = ();
  my @tmp2 = ();
  print OUT "$a[2]\t$a[0]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\t$a[7]";
  print FPM "$a[2]\t$a[0]\t$a[3]\t$a[4]\t$a[5]\t$a[6]\t$a[7]";
  foreach my $s (@samples) {
    print OUT "\t$count{$s}{$a[0]}";
    push @tmp1, $count{$s}{$a[0]};
    my $fpkm = sprintf("%.4f", 1000000000*$count{$s}{$a[0]}/($a[$#a]*$sum{$s}));
    print FPM "\t$fpkm";
    push @tmp2, $fpkm;
  }
  print OUT "\n";
  print FPM "\n";
  if ($a[3] =~ /protein_coding/) {
    print OUT1 "$a[2]\t$a[0]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t";
    print OUT1 join("\t", @tmp1), "\n";
    print FPM1 "$a[2]\t$a[0]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t";
    print FPM1 join("\t", @tmp2), "\n";
  }
  if ($a[3] =~ /lincRNA/) {
    print OUT2 "$a[2]\t$a[0]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t";
    print OUT2 join("\t", @tmp1), "\n";
    print FPM2 "$a[2]\t$a[0]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t";
    print FPM2 join("\t", @tmp2), "\n";
  }
  if ($a[3] =~ /antisense/) {
    print OUT3 "$a[2]\t$a[0]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t";
    print OUT3 join("\t", @tmp1), "\n";
    print FPM3 "$a[2]\t$a[0]\t$a[4]\t$a[5]\t$a[6]\t$a[7]\t";
    print FPM3 join("\t", @tmp2), "\n";
  }
}
close (IN);
close (OUT);
close (OUT1);
close (OUT2);
close (OUT3);
close (FPM);
close (FPM1);
close (FPM2);
close (FPM3);

open(OUT, ">nofeature-summary.txt");
print OUT "Sample\tNo-Feature\tMapped\n";
foreach my $s (@samples) {
  print OUT "$s\t$count{$s}{'no_feature'}\t$sum{$s}\n";
}

