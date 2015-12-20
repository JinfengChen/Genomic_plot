#!usr/bin/perl
use strict;

die "perl $0 <chr> <len> <soap>\n" if(@ARGV != 3);
my ($chr, $len_file, $soap) = @ARGV;

my $window = 100000;

$chr =~ s/chr/A/;
my $len;
open(FH, $len_file) || die $!;
while(<FH>)
{
	chomp;
	my @tmp = split /\s+/;
	if($chr eq $tmp[0])
	{
		$len = $tmp[1];
		last;
	}
}
close FH;

my $cov = "0" x $len;

open(FH, $soap) || die $!;
while(<FH>)
{
	chomp;
	my @tmp = split /\s+/;
	$tmp[7] =~ s/chr/A/;
	next if($tmp[3] != 1 or $tmp[7] ne $chr);
	my $rna_len = $tmp[5];
	my $location = $tmp[8] - 1;
	substr($cov, $location, $rna_len) = "1" x $rna_len;
}
close FH;

my $total = int($len / $window) + 1;
for my $i (0..$total-1)
{
	my $pos = $i * $window;
	my $sub_cov = substr($cov, $pos, $window);
	my $count = $sub_cov =~ s/1/2/g;
	$count = $count / $window;
	print "$chr\tRNA-Seq\t$i\t$count\t$total\n";
}
