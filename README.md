GeneAtlas
=========

DESCRIPTION

GeneAtlas is simple gene enrichment in normal tissue expression profiles.
We have a selection of publically available data sets for normal human tissue profiling, all data sets are located in the data/ directory, after gene normalization and quantification, please contact me if you want more details about the data preprocessing.
Input are a selection of tissues to compare, output is a text file with the 
weigthed gene list [0,1).

USAGE

geneatlas.pl [PARAMETERS]

   Parameters       Description
   
   -d --dataset     Select data set to use, "all" shows all data sets available.

   -l --list        List samples in data set.

   -s --select      Select samples, the value is a list of numbers or the name 
                    of the samples, a basic RegEx is applied in text mode. 
                    Multiple sources can be separated by commas.

   -e --exclude     Exclude samples, similar to "select" option, but it will
                    skip the samples in the computation.

   -m --method      Method for enrichment, multiple values are collapsed using:
                    a) maximal [default], b) average
                   
   -t --transcript  Report genes at the transcript level (default is collapsing
                    transcripts values to the gene level).

   -o --out         Write ouput to this file [default: stdout]
   
   -h --help        Show this screen.
   
   -v --verbose     Activate verbose mode.
   
      --version     Print version and exit.
   
EXAMPLES

 1. Show available data sets
    perl bin/geneatlas.pl -d all
    
 2. Show samples in one data set
    perl bin/geneatlas.pl -d GSE1133 -l
    
 3. Compute enrichment in the Appendix in data set GSE1133_microrray
    perl bin/geneatlas.pl -d GSE1133_microrray -s 7
    perl bin/geneatlas.pl -d GSE1133_microrray -s Appendix # this also works
    
 4. Compute enrichment in the Appendix in data set GSE1133_microrray excluding CD* samples 
    perl bin/geneatlas.pl -d GSE1133_microrray -s 7 -e 10,15,20,29,36,38,43,61,66
    perl bin/geneatlas.pl -d GSE1133_microrray -s Appendix -e CD # this also works
 
 5. Change the method to average values
    perl bin/geneatlas.pl -d GSE1133_microrray -s 7 -m average

AUTHOR

Juan Caballero, Institute for Systems Biology @ 2012

