#!usr/bin/perl
use strict;

die "perl $0 <chr> <len> <bed>\n" if(@ARGV != 3);
my ($chr, $len_file, $bed) = @ARGV;

$chr =~ s/chr/A/;
my $window = 100000;

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

open(FH, $bed) || die $!;
while(<FH>)
{
	chomp;
	my @tmp = split /\s+/;
	$tmp[0] =~ s/chr/A/;
	next if($tmp[0] ne $chr);
	next if($tmp[1] > $len);
	substr($cov, $tmp[1], 1) = "1";
}
close FH;

my $total = int($len / $window) + 1;;
for my $i (0..$total-1)
{
	my $pos = $i * $window;
	my $sub_cov = substr($cov, $pos, $window);
	my $count = $sub_cov =~ s/1/2/g;
	$count = $count / $window;
	print "$chr\tMethylation\t$i\t$count\t$total\n";
}
