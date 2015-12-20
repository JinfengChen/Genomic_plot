#!/usr/bin/perl
use Getopt::Long;

GetOptions (\%opt,"chr:s","riceTE:s","ffTE:s","riceGene:s","ffGene:s","riceRNA:s","ffRNA:s","riceMe:s","ffMe:s","help");


my $help=<<USAGE;
The pipeline will draw heatmap figure for one chromosome automaticly.

--chr    : chr number to draw
--riceTE : dir of rice TE annotation gff file, one file for each chromosome
--ffTE   : dir of ff TE annotation gff file, one file for each chromosome
--riceGene: dir of rice Gene annotation gff file, one file for each chromosome 
--ffGene: dir of ff Gene annotation gff file, one file for each chromosome 

Run: perl headmapPipe.pl -chr chr12 -riceTE ../input/IRGSP.build5.RepeatMasker.out.gff.chr -ffTE ../input/OBa.all.fa.RepeatMasker.out.gff.chr -ffGene ../input/OBa.all.gff.chr -riceGene ../input/RAP3.gff3.nr.gff.chr > log 2> log2 &
 
USAGE


if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
} 



my $drawdir="../input/$opt{chr}";
mkdir $drawdir unless (-e $drawdir);

###split riceTE
my $riceTEchr="$opt{riceTE}"."/"."$opt{chr}";
print "$riceTEchr\n";
splitTE($riceTEchr,"$drawdir/Rice");

###split ffTE
my $ffTEchr="$opt{ffTE}"."/"."$opt{chr}";
print "$ffTEchr\n";
splitTE($ffTEchr,"$drawdir/FF");

###cp riceGene
my $riceGenechr="$opt{riceGene}"."/"."$opt{chr}";
cpGene($riceGenechr,"$drawdir/Rice");

###cp ffGene
my $ffGenechr="$opt{ffGene}"."/"."$opt{chr}";
cpGene($ffGenechr,"$drawdir/FF");

##### prepare FF and Rice
my $chr="$opt{chr}";
$chr=~s/chr/A/;

my $riceRNA = "$opt{riceRNA}";
my $ffRNA = "$opt{ffRNA}";

my $riceMe = "$opt{riceMe}";
my $ffMe = "$opt{ffMe}";

print "Preparing densi and distri files ...\n";
prepare($drawdir,$chr,"FF","../input/fflen","../input/ffpara.gene.new",$ffRNA, $ffMe);
prepare($drawdir,$chr,"Rice","../input/ricelen","../input/ricepara.gene.new",$riceRNA, $riceMe);



##### prepare connect file.
print "Preparing connect.txt and all.gene.positions files ...\n";
system ("perl connect.pl -table ../input/ob_os.blast.new -gff1 $drawdir/FF.Gene.gff -gff2 $drawdir/Rice.Gene.gff > log 2> log2");

##### draw headmap
print "Draw HeadMap ...\n";
system ("perl Draw_HeatMap_lg.pl $chr.Rice.data.distri $chr.Rice.data.densi $chr.FF.data.distri $chr.FF.data.densi all.gene.position connect.txt >log 2>log2");

##### svg2pdf
system ("/share/raid12/chenjinfeng/tools/draw/svg2xxx_release/svg2xxx -t pdf -m 400 $chr.FF.HeatMap.svg");
##### clear temp files
#system ("rm *.densi *.distri");
system ("rm all.gene.position connect.txt");

`rm -r ../output/$chr` if( -e "../output/$chr");
`mkdir ../output/$chr`;
`mv $chr.Rice.data.distri ../output/$chr/$chr.Rice.data.distri`;
`mv $chr.Rice.data.densi ../output/$chr/$chr.Rice.data.densi`;
`mv $chr.FF.data.distri ../output/$chr/$chr.FF.data.distri`;
`mv $chr.FF.data.densi ../output/$chr/$chr.FF.data.densi`;
`mv $chr.FF.HeatMap.svg ../output/$chr/$chr.FF.HeatMap.svg`;
`mv $chr.FF.HeatMap.pdf ../output/$chr/$chr.FF.HeatMap.pdf`;

###################################################

sub prepare
{
my ($dir,$chr,$species,$len,$para,$rna,$me)=@_;
system ("perl remove_redundance.pl $dir/$species.RT.gff $dir/$species.DNA.gff $dir/$species.Gene.gff >log 2> log2");
system ("perl distri_data_pre.pl $len distri.gff.nr.out > log 2> log2");
system ("perl get_sub_gff.pl -list $para -gff $dir/$species.Gene.gff -output $para.gff");
system ("perl get_paralog_exons.pl $para.gff");
system ("perl get_introns_exons.pl $dir/$species.Gene.gff");
system ("perl density_data_pre.pl $len $dir/$species.GYPSY.gff $dir/$species.COPIA.gff $dir/$species.MUDR.gff $dir/$species.MITE.gff gene_exons.gff paralog_exons.gff > log 2> log2");

system ("mv $chr.data.distri $chr.$species.data.distri");
system ("mv $chr.data.densi $chr.$species.data.densi");
system ("rm *.gff distri.gff.nr.out");

system ("perl rnaseq_data_pre.pl $chr $len $rna >rna.densi");
system ("perl methylation_data_pre.pl $chr $len $me >me.densi");

system ("grep LTR $chr.$species.data.densi >tmp");
system ("grep Paralogs $chr.$species.data.densi >>tmp");
system ("grep Genes $chr.$species.data.densi >>tmp");
system ("cat tmp rna.densi me.densi >$chr.$species.data.densi");

system ("rm rna.densi me.densi tmp");
}

sub cpGene
{
my ($gff,$prefix)=@_;
my $target=$prefix.".Gene.gff";
open IN, "$gff" or die "$!";
open GENE, ">$target" or die "$!";
while(<IN>){
   next if ($_ eq "");
   next if ($_ =~/^#/);
   my @temp=split("\t",$_);
   $temp[0]=~s/chr/A/;
   my $line=join("\t",@temp);
   print GENE "$line"; 
}
close GENE;
close IN;
}


sub splitTE
{
my ($gff,$prefix)=@_;
open IN, "$gff" or die "$!";
open DNA, ">$prefix.DNA.gff" or die "$!";
open RT, ">$prefix.RT.gff" or die "$!";
open CACTA, ">$prefix.CACTA.gff" or die "$!";
open MITE, ">$prefix.MITE.gff" or die "$!";
open MUDR, ">$prefix.MUDR.gff" or die "$!";
open GYPSY, ">$prefix.GYPSY.gff" or die "$!";
open COPIA, ">$prefix.COPIA.gff" or die "$!";
while(<IN>){
    next if ($_ eq "");
    next if ($_ =~/^#/);
    my @temp=split("\t",$_);
    $temp[0]=~s/chr/A/;
    my $line=join("\t",@temp);
    my $TE_class= $1 if ($temp[8] =~ /Class=([^;]+);*/);
    #print "$TE_class\n";
    if ($TE_class =~/^DNA/){
       print DNA "$line";
    }elsif($TE_class=~/^LTR/){
       print RT "$line";
    } 
    if ($TE_class=~/En-Spm/i){
       print CACTA "$line"; 
    }elsif($TE_class=~/MuDR/i){
       print MUDR "$line";
    }elsif($TE_class=~/Stowaway/i or $TE_class=~/Tourist/i or $TE_class=~/MITE/i){
       print MITE "$line";
    }elsif($TE_class=~/Gypsy/i){
       print GYPSY "$line";
    }elsif($TE_class=~/Copia/i){
       print COPIA "$line";
    }
}
close GYPSY;
close COPIS;
close MUDR;
close MITE;
close CACTA;
close DNA;
close RT;
close IN;
}



