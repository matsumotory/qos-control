#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::CheckBase;

use strict;
our $VERSION = '0.01';

sub yes_or_no {

    my ($self, $output) = @_;

    print "$output: continue? [yes or no]: ";

    while (my $input = <STDIN>) {
        chomp($input);
        if ($input eq 'yes') {
            last;
        } elsif ($input eq 'no') {
            print "cancelled.\n";
            exit(1);
        } else {
            print "$input is invalid.\n";
        }
        print "$output: continue? [yes or no]: ";
    }
}


1;
