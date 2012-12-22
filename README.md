GeneAtlas
=========

DESCRIPTION

GeneAtlas is a simple gene enrichment in normal tissue expression profiles.
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

      -c --score       Method to compute the score: a) norlog, b) wilson [default].
                       "norlog" is the normalized value of the log-enriched-ratio
                       multiplied by the normalized expression level.
                       "wilson" is the lower bound of Wilson score confidence 
                       interval for a Bernoulli parameter (95% conf.)
      
      -t --transcript  Report genes at the transcript level (default is collapsing
                       transcripts values to the gene level).
      
      -o --out         Write ouput to this file [default: stdout]
      
      -h --help        Show this screen.
      
      -v --verbose     Activate verbose mode.
      
      --version        Print version and exit.

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

DATA SOURCES

Microarray data is processed from raw data (CEL files) with 
R:Bioconductor affy and limma packages, all samples are normalized
with "rma".

RNAseq data is precessed from raw reads (FASTQ files), after removing 
low quality reads, repeats and ribosomal sequences, the reads are mapped
to the reference genome hg19/GRCh37 with and optimized version of Blat, 
then converted to BAM and transcript quantification with Cufflinks using
the gene models of Ensembl r64.

*GSE1133_microrray* was obtained from: 
http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE1133 
[Su AI, Wiltshire T, Batalov S, Lapp H et al. A gene atlas of the mouse 
and human protein-encoding transcriptomes. Proc Natl Acad Sci U S A 2004
Apr 20;101(16):6062-7. PMID: 15075390.]

*GSE2361_microarray* was obtained from:
http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE2361
[Ge X, Yamamoto S, Tsutsumi S, Midorikawa Y et al. Interpreting expression
profiles of cancers by genome-wide survey of breadth of expression in 
normal tissues. Genomics 2005 Aug;86(2):127-41. PMID: 15950434.]

*GSE3526_microarray* was obtained from: 
http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE3526 
[Roth RB, Hevezi P, Lee J, Willhite D et al. Gene expression analyses 
reveal molecular relationships among 20 regions of the human CNS. 
Neurogenetics 2006 May;7(2):67-80. PMID: 16572319.]

*bodymap1_rnaseq* was obtained from: 
http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE12946
[Wang ET, Sandberg R, Luo S, Khrebtukova I et al. Alternative isoform 
regulation in human tissue transcriptomes. Nature 2008 
Nov 27;456(7221):470-6.]

*bodymap2_rnaseq* was kindly provided by Gary Schroth (Illumina Co.) 
The reads are 75b single ends produced in HiSeq2000.

*rnaseq_atlas_rev1* was obtained from: 
http://medicalgenomics.org/rna_seq_atlas
[Castle JC, Armour CD, Löwer M, Haynor D, Biery M, et al. (2010) Digital
Genome-Wide ncRNA Expression, Including SnoRNAs, across 11 Human Tissues
Using PolyA-Neutral Amplification. PLoS ONE 5(7): e11779. 
doi:10.1371/journal.pone.0011779]

DATA TABLES

The data tables are simple tab-delimited text files, each row represents
a transcript, the first column is the gene symbol, the second the transcript
or probe id, the rest of the columns are the values (RPKM for RNAseq, UF for
microarrays) in each tissue.

AUTHOR

Juan Caballero, Institute for Systems Biology @ 2012

