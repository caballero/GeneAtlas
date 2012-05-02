#!/usr/bin/perl

=head1 NAME

geneatlas.pl

=head1 DESCRIPTION

GeneAtlas is simple gene enrichment in normal tissue expression profiles.
Input are a selection of tissues to compare, output is a text file with the 
weigthed gene list [0,1).

=head1 USAGE

geneatlas.pl [PARAMETERS]

   Parameters      Description
   
   -d --dataset    Select data set to use, "all" shows all data sets available.

   -l --list       List samples in data set.

   -s --select     Select samples, the value is a list of numbers or the name 
                   of the samples, a basic RegEx is applied in text mode. 
                   Multiple sources can be separated by commas.

   -e --exclude    Exclude samples, similar to "select" option, but it will
                   skip the samples in the computation.

   -m --method     Method for enrichment, multiple values are collapsed using:
                   a) maximal [default], b) average

   -o --out        Write ouput to this file [default: stdout]
   
   -h --help       Show this screen.
   
   -v --verbose    Activate verbose mode.
   
      --version    Print version and exit.
   
=head1 EXAMPLES

 1. Show available data sets
    perl geneatlas.pl -d all
    
 2. Show samples in one data set
    perl geneatlas.pl -d GSE1133 -l
    
 3. COmpute enrichment in the Appendix in data set GSE1133
    perl geneatlas.pl -d GSE1133 -s 7
    perl geneatlas.pl -d GSE1133 -s Appendix # this also works
    
 4. Compute enrichment in the Appendix in data set GSE1133 excluding CD* samples 
    perl geneatlas.pl -d GSE1133 -s 7 -e 10,15,20,29,36,38,43,61,66
    perl geneatlas.pl -d GSE1133 -s Appendix -e CD # this also works
 
 5. Change the method to average values
    perl geneatlas.pl -d GSE1133 -s 7 -m average

=head1 AUTHOR

Juan Caballero, Institute for Systems Biology @ 2012

=head1 CONTACT

jcaballero@systemsbiology.org

=head1 LICENSE

This is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with code.  If not, see <http://www.gnu.org/licenses/>.

=cut

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

# Default parameters
my $help          = undef;      # Print help
my $verbose       = undef;      # Verbose mode
my $version       = undef;      # Version call flag
my $dataset       = 'all';
my $list          = undef;
my $select        = undef;
my $exclude       = undef;
my $method        = 'maximal';
my $out           = undef;

# Main variables
my $our_version   = 0.1;        # Script version number
my $datadir       = 'data';     # Where to find the data sets
my $max_sp        = -100;
my %select        = ();
my %contrast      = ();
my %sp            = ();

# Calling options
GetOptions(
    'h|help'      => \$help,
    'v|verbose'   => \$verbose,
    'version'     => \$version,
    'd|dataset:s' => \$dataset,
    'l|list'      => \$list,
    's|select:s'  => \$select,
    'e|exclude:s' => \$exclude,
    'm|method:s'  => \$method,
    'o|out:s'     => \$out
) or pod2usage(-verbose => 2);
    
pod2usage(-verbose => 2) if (defined $help);
printVersion() if (defined $version);

# Input quick check up
showDatasets() if ($dataset =~ m/all/i);
unless (-e "$datadir/$dataset.samples") {
    die "Data set $dataset not found in $datadir\n";
}
showSamples() if (defined $list);
unless ($method =~ m/maximal|average/) {
    die"Unknown method: $method\nSupported are 'maximal' and 'average'\n";
}

# Obtain list of samples to process
readSamples();

# Create output file if required
if (defined $out) {
    open STDOUT, ">$out" or die "cannot create $out\n";
}

## MAIN PROCESS
warn "reading data\n" if (defined $verbose);
my $fh = "gunzip -c $datadir/$dataset.tab.gz | ";
open DAT, "$fh" or die "cannot open $datadir/$dataset.tab.gz\n";
while (<DAT>) {
    chomp;
    next if (m/^GeneSymbol/i);
    my ($gene, $probe, @values) = split (/\t/, $_);
    next if ($gene eq '-'); # skip missing gene ids
    my $sp = specificity(\@values);
    $sp{"$gene\t$probe"} = $sp;
    $max_sp = $sp if ($sp > $max_sp);
}
close DAT;

warn "normalizing values\n" if (defined $verbose);
while ( my ($id, $sp) = each %sp) {
    my $nsp = $sp / $max_sp;
    print "$id\t$nsp\n";
}

###################################
####   S U B R O U T I N E S   ####
###################################

# printVersion => Return version number
sub printVersion {
    print "$0 version $our_version\n";
    exit 1;
}

# showDatasets => List available datasets in $datadir
sub showDatasets {
    print "Available datasets:\n";
    opendir D, "$datadir" or die "cannot read $datadir\n";
    while (my $file = readdir D) {
        if ($file =~ m/samples$/) {
            $file =~ s/.samples//;
            print "  $file\n";
        }
    }
    closedir D;
    exit 1;
}

# showSamples => List available samples in $dataset
sub showSamples {
    print "Available samples in $dataset:\n";
    my $n = 0;
    open F, "$datadir/$dataset.samples" or die "cannot open $datadir/$dataset.samples\n";
    while (<F>) {
        chomp;
        $n++;
        print "[$n]\t$_\n";
    }
    close F;
    exit 1;
}

# readSamples => Obtain the list of samples to compare
sub readSamples {
    my @sel = split (/,/, $select);
    my @exc = split (/,/, $exclude);
    
    my $n = 0;
    warn "looking for samples\n" if (defined $verbose);
    open F, "$datadir/$dataset.samples" or die "cannot open $datadir/$dataset.samples\n";
    while (<F>) {
        chomp;
        $n++;
        foreach my $s (@sel) {
            if ($s =~ m/^\d+$/) {
                $select{$n - 1} = $_ if ($s == $n);
                next;
            }
            else {
                $select{$n - 1 } = $_ if (m/$s/i);
                next;
            }
        }
        
        foreach my $e (@exc) {
            if ($e =~ m/^\d+$/) {
                next if ($e == $n);
            }
            else {
                next if (m/$e/i);
            }
        }
        
        $contrast{$n - 1} = $_;
    }
    close F;
    my $s = join ",", sort values %select;
    my $c = join ",", sort values %contrast;
    warn "Selected: $s\nContrast: $c\n" if (defined $verbose);
}

# specificity => Compute the specificity score
sub specificity {
    my @val = @_;
    my @sel = ();
    my @con = ();
    my $sp  =  0;
    my $sel =  0;
    my $con =  0;
    for (my $i = 0; $i <= $#val; $i++) {
        push @sel, $val[$i] if (defined $select{$i});
        push @con, $val[$i] if (defined $contrast{$i});
    }
    if ($method eq 'maximal') {
        $sel = max(@sel);
        $con = max(@con);
    }
    elsif ($method eq 'average') {
        $sel = mean(@sel);
        $con = mean(@con);
    }
    
    $sp = $sel - $con;
    return $sp;
}


# max => Returns maximal value
sub max {
    my $max = -1;
    foreach my $x (@_) {
        $max = $x if ($x > $max);
    }
    return $max;
}

# mean => Returns mean value
sub mean {
    my $mean = -1;
    my $num  =  0;
    my $sum  =  0;
    foreach my $x (@_) {
        $num++;
        $sum += $x;
    }
    return $sum / $num;
}
