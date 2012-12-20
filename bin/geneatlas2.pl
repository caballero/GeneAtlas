#!/tools64/bin/perl

=head1 NAME

geneatlas2.pl

=head1 DESCRIPTION

web interface for GENTLE.

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
use CGI::Pretty qw/:standard/;

# Connecting to the DB
my $db_file  = 'GeneAtlas.db';
my $dbh      = DBI->connect("dbi:SQLite:dbname=$db_file", "", "") or fatalError("Cannot connect to $
db_file: Abort");
my $sth      = '';
my $sql      = '';
my $our_url  = 'http://osiris.systemsbiology.net/~jcaballe/cgi-bin/GA2';
my @datasets = qw/GSE1133_microarray GSE3526_microarray bodymap2_rnaseq rnaseq_atlas_rev1 GSE2361_microarray bodymap1_rnaseq feastseq_rnaseq/;

#include the header in SQLite
$sql = '.header ON';
$sth = $dbh->prepare("$sql")  or fatalError("Error: preparing query '$sql'");
$sth-> execute() or fatalError("Error: executing query '$sql'");
	
# CSS definition
my $style   =<<__STYLE__
<style type="text/css">
    body  { color: navy; background: lightyellow }
    h1    { color: navy; }
    table { border: 2px solid grey; border-collapse: collapse }
    th    { text-align: center; font-weight: bold; border: 2px solid grey; padding: 5px }
    td    { text-align: left; border: 1px solid grey; padding: 5px }
</style>
__STYLE__
;

# HTML header
print header('text/html'); 

if (defined param('query')) {
    print "<html>\n<head>\n<title>Gene Atlas Interface</title>\n$style\n";
    
    my $query = param('query');
    my $table = param('dataset');
    my $data  = "var data = google.visualization.arrayToDataTable([\n";
    
    $sql = "SELECT * FROM $table WHERE gene = '$query' or id = '$query';";
    $sth = $dbh->prepare("$sql")  or fatalError("Error: preparing query '$sql'");
	$sth-> execute() or fatalError("Error: executing query '$sql'");
	while (my @data = $sth->fetchrow_array()) {
	    my $gen = shift @data;
	    my $id  = shift @data;
	    if ($gen eq 'gene') {
	        $data .= "['ID'";
	        foreach my $sample (@data) { $data .= ",'$sample'"; }
	        $data .= "],\n";
	    }
	    else {
	        $data .= "['$gen:$id'";
	        foreach my $value (@data) { $data .= ",$value"; }
	        $data .= "],\n";
	    }
	}
	$data =~ s/,\n$/\n/;
	$data .= "]);\n";
	if ($sth->rows == 0) {
	    print "</head>\n";
		print p("No gene found with $query!");
	}
	else {
	    print <<__CHART__
  <script type="text/javascript" src="https://www.google.com/jsapi"></script>
  <script type="text/javascript">
    google.load("visualization", "1", {packages:["corechart"]});
    google.setOnLoadCallback(drawChart);
    function drawChart() {
      $data
      
      var options = {
        title: '$query'
      };
      
      var chart = new google.visualization.ColumnChart(document.getElementById('chart_div'));
      chart.draw(data, options);
        }
  </script>
  </head>
  <body>
    <div id="chart_div"></div>
  </body>
__CHART__
;
    }
}
else {
    print "<html>\n<head>\n<title>Gene Atlas Interface</title>\n$style\n</head>\n<body>";
    print start_form();
    print p("Search Gene: ", 
            textfield(-name => 'query', -size => 10),
            " in ",
            popup_menu(-name => 'dataset', -values => \@datasets, -default => 'bodymap2_rnaseq')
           );
	print submit(-name => 'Get Expression');
	print end_form();
}
    
# HTML footer
print p(i('Contact: Juan Caballero','<br>', 'Institute for Systems Biology (2012)'));
print end_html;

# Shut down the DB connection
$sth->finish();
$dbh->disconnect();

sub fatalError {
	my $mes = shift @_;
	print	h2("Unhappy ending: $mes"),
	end_html();
	exit 1;
}
