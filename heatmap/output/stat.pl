#!usr/bin/perl
use strict;

die "perl $0 <dirname>\n" if(@ARGV != 1);
my ($dirname) = @ARGV;

my @location = <$dirname/*/*>;

foreach my $file (@location)
{
        next if($file =~ /svg/ or $file =~ /pdf/);

        my (%max, %min);
        my $id = "";
        open(FH, $file) || die $!;
        while(<FH>)
        {
                chomp;
                my @tmp = split /\t/;
                $id = $tmp[0] if($id eq "");
                my $type = $tmp[1];
                $max{$type} = 0 if(not exists $max{$type});
                $min{$type} = 100 if(not exists $min{$type});
                $max{$type} = $tmp[3] if($max{$type} < $tmp[3]);
                $min{$type} = $tmp[3] if($min{$type} > $tmp[3]);
        }
        close FH;

        open(OUT, ">$file.stat") || die $!;
        for my $type (keys %max)
        {
                print OUT "$id\t$type\t$min{$type}\t$max{$type}\n";
        }
        close OUT;
}

