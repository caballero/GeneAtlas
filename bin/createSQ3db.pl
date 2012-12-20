#!/usr/bin/perl

=head1 NAME

createSQ3db.pl

=head1 DESCRIPTION

Create a combined SQLite3 database with all samples in data/, each dataset
is represented as a table, the first two columns are the gene and transcript/
probe identifiers, the rest are the tissue expression.

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
use DBI;

my $db  = 'GeneAtlas.db';
my $dir = "./data";

# Delete the old version
unlink $db if (-e $db);
system ("touch $db");

# Connecting to the DB
my $dbh = DBI->connect("dbi:SQLite:dbname=$db", "", "") or die "Cannot connect to $db\n";
my $sth = '';
my $sql = '';

opendir D, "$dir" or die "cannot read $dir\n";
while (my $file = readdir D) {
    next unless ($file =~ m/samples$/);
    my $name = $file; 
    $name =~ s/.samples//;
    next if ($name =~ m/prot$/);
    
    # load sample names
    open F, "$dir/$file" or die "cannot open $dir/$file\n";
    my @samples = <F>;
    chomp (@samples);
    close F;
    
    # create the table
    $sql = "CREATE TABLE $name (gene TEXT, id TEXT,";
    while (my $sample = shift @samples) {
        $sample =~ s/\./_/g;
        $sample =~ s/-/_/g;
        $sample =~ s/\//_/g;
        $sql   .= " $sample REAL,";
    }
    $sql =~ s/,$/);/;
    warn "SQL# $sql\n";
    $sth = $dbh->prepare("$sql") or die "error preparing $sql\n";
    $sth-> execute() or die "error executing $sql\n";
    
    # load the data
    open T, "gunzip -c $dir/$name.tab.gz | " or die "cannot open $dir/$name.tab.gz\n";
    while (<T>) {
        chomp;
        next if (m/^Gene/);
        my @values  = split (/\s+/, $_);
        $values[0]  = "\"$values[0]\"";
        $values[1]  = "\"$values[1]\"";
        my $values  = join ",", @values;
        $sql        = "INSERT INTO $name VALUES ($values);";
        $sth = $dbh->prepare("$sql") or die "error preparing $sql\n";
        $sth-> execute() or die "error executing $sql\n";
    }
    close T;    
}

# Shut down the DB connection
$sth->finish();
$dbh->disconnect();
