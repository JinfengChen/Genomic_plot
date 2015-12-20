#!/usr/bin/perl
use strict;

die "perl $0 <dir>\n" if(@ARGV != 1);
my $dir = shift;

my @file= `ls $dir`;
foreach (@file){
   chomp;
   #print "$_\n";die;
   my $file="$dir/$_";
   unless ($file=~/control/i){
      open (IN, "gzip -dc $file|") || die $!;
      while(<IN>){
           chomp $_;
           next if ($_ eq "");
           my @unit=split("\t");
           next if ($unit[6] < $unit[8] or $unit[6] < 2);
           my $start=$unit[1]-1;
           my $end=$start;
           print "$unit[0]\t$start\t$end\t$unit[6]\t$unit[8]\t$unit[2]\n";
      }
      close IN;
   }
}
