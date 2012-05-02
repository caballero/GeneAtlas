#!/usr/bin/perl

=head1 NAME

roundValues.pl

=head1 DESCRIPTION

Round the numerical values in a table, first 2 elements are labels.

=head1 USAGE

perl roundValues.pl < TABLE > OUT

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

while (<>) {
    if (m/^GeneSymbol/i) { # skip the header row
        print $_;
        next;
    }
    chomp;
    my @a = split (/\t/, $_);
    for (my $i = 2; $i <= $#a; $i++) {
        next if ($a[$i] == 0); # don't round zeros
        $a[$i] = sprintf("%.2f", $a[$i]);
    }
    print join "\t", @a;
    print "\n";
}
