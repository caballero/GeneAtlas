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
    
    my $query  = param('query');
    my $table  = param('dataset');
    my $width  = param('width');
    my $height = param('height');
    my @data   = ();
    my $data   = "var data = new google.visualization.DataTable();\n";
       $data  .= "data.addColumn('string','Tissue');\n";   
    # Get samples names
    $sql = "SELECT * FROM samples WHERE dataset = '$table';";
    $sth = $dbh->prepare("$sql")  or fatalError("Error: preparing query '$sql'");
	$sth-> execute() or fatalError("Error: executing query '$sql'");
	while (my ($id, $samples) = $sth->fetchrow_array()) {
	    my @samples = split (/,/, $samples);
	    foreach my $sample (@samples) { push @data, "'$sample'";  }
	    last; # only the fist one
	}
	
	# Get data
    $sql = "SELECT * FROM $table WHERE gene LIKE '$query' or id LIKE '$query' LIMIT 100;";
    $sth = $dbh->prepare("$sql")  or fatalError("Error: preparing query '$sql'");
	$sth-> execute() or fatalError("Error: executing query '$sql'");
	while (my @res = $sth->fetchrow_array()) {
	    my $gen   = shift @res;
	    my $id    = shift @res;
	    $data    .= "data.addColumn('number','$id');\n";
	    my $i     = 0;
	    foreach my $val (@res) {
	        $val = sprintf ("%.2f", $val);
	        $data[$i] .= ",$val";
	        $i++;
	    }
	}
	
	$data .= "data.addRows([\n";
	foreach my $row (@data) {
	    $data .= "[$row],\n";
	}
	$data  =~ s/,$//;
	$data .= "]);\n";
	
	if ($sth->rows == 0) {
	    print "</head>\n";
		print p("No gene found with $query!");
	}
	# print chart
	else {
	    print <<__CHART__
  <script type="text/javascript" src="https://www.google.com/jsapi"></script>
  <script type="text/javascript">
    google.load("visualization", "1", {packages:["corechart"]});
    google.setOnLoadCallback(drawChart);
    function drawChart() {
      $data
      
      var options = {
        title: '$query in $table',
        width:  $width,
        height: $height
      };
      
      var chart = new google.visualization.ColumnChart(document.getElementById('chart_div'));
      chart.draw(data, options);
        }
  </script>
  </head>
  <body>
    <h2>GENTLE: Gene Expression in Normal Tissues</h2>
    <hr>
    <div id="chart_div"></div>
  </body>
__CHART__
;
    }
}
elsif (defined param('tissue')) {
    print "<html>\n<head>\n<title>Gene Atlas Interface</title>\n$style\n";
    
    my $tissue = param('tissue');
    my $table  = param('dataset');
    my $minexp = param('minexp');
    my $maxexp = param('maxexp');
    my @data   = ();
    my $data   = "var data = new google.visualization.DataTable();\n";
       $data  .= "data.addColumn('string','Tissue');\n";   
    # Get samples names
    $sql = "SELECT * FROM samples WHERE dataset = '$table';";
    $sth = $dbh->prepare("$sql")  or fatalError("Error: preparing query '$sql'");
	$sth-> execute() or fatalError("Error: executing query '$sql'");
	while (my ($id, $samples) = $sth->fetchrow_array()) {
	    my @samples = split (/,/, $samples);
	    foreach my $sample (@samples) { push @data, "'$sample'";  }
	    last; # only the fist one
	}
	
	# Get data
    $sql = "SELECT * FROM $table WHERE $tissue >= $minexp and $tissue <= $maxexp)";
    $sth = $dbh->prepare("$sql")  or fatalError("Error: preparing query '$sql'");
	$sth-> execute() or fatalError("Error: executing query '$sql'");
	while (my @res = $sth->fetchrow_array()) {
	    my $gen   = shift @res;
	    my $id    = shift @res;
	    $data    .= "data.addColumn('number','$gen:$id');\n";
	    my $i     = 0;
	    foreach my $val (@res) {
	        $val = sprintf ("%.2f", $val);
	        $data[$i] .= ",$val";
	        $i++;
	    }
	}
	
	$data .= "data.addRows([\n";
	foreach my $row (@data) {
	    $data .= "[$row],\n";
	}
	$data  =~ s/,$//;
	$data .= "]);\n";
	
	if ($sth->rows == 0) {
	    print "</head>\n";
		print p("No genes found with $tissue in $table [$minexp-$maxexp]!");
	}
	# print chart
	else {
	    print <<__CHART__
  <script type="text/javascript" src="https://www.google.com/jsapi"></script>
  <script type="text/javascript">
    google.load("visualization", "1", {packages:["table"]});
    google.setOnLoadCallback(drawTable);
    function drawTable() {
      $data
      
      var table = new google.visualization.Table(document.getElementById('table_div'));
      table.draw(data, {showRowNumber: true});
    }
  </script>
  </head>
  <body>
    <h2>GENTLE: Gene Expression in Normal Tissues</h2>
    <hr>
    <p>Search: $tissue in $table [$minexp-$maxexp]</p>
    <div id="table_div"></div>
  </body>
__CHART__
}
else {
    print "<html>\n<head>\n<title>Gene Atlas Interface</title>\n$style\n</head>\n<body>";
    print h2("GENTLE: Gene Expression in Normal Tissues"), hr();
    print start_form();
    print p("Search Gene: ", 
            textfield(-name => 'query', -size => 10),
            " in ",
            popup_menu(-name => 'dataset', -values => \@datasets, -default => 'bodymap2_rnaseq')
           );
    print p("Width: ", 
            textfield(-name =>  'width', -size => 4, -value => 900),
            " Height: ",
            textfield(-name => 'height', -size => 4, -value => 300),
           );
	print submit(-name => 'Plot Expression');
	print hr();
	print p("Search Tissue: ",
	        textfield(-name =>  'tissue', -size => 10),
	        " in ",
	        popup_menu(-name => 'dataset', -values => \@datasets, -default => 'bodymap2_rnaseq'),
	       );
	print p("Genes with expression between: ",
	        textfield(-name =>  'minexp', -size => 4, -value 0.01),
	        "-",
	        textfield(-name =>  'maxexp', -size => 4, -value 1000)
	       );
	print submit(-name => 'Get Expression');
	print end_form();
}
    
# HTML footer
print p(i('Contact: Juan Caballero','<br>', 'Institute for Systems Biology (2012)'));
print end_html;

# Shut down the DB connection
$dbh->disconnect();

sub fatalError {
	my $mes = shift @_;
	print	h2("Unhappy ending: $mes"),
	end_html();
	exit 1;
}
