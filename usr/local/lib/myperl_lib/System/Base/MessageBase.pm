#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::MessageBase;

use strict;
our $VERSION = '0.01';

sub info_message {

    my ($self, $output, $info) = @_;

    print "INFO    : output=($output)\n" if ($info == 1);

}

sub debug_message {

    my ($self, $output, $debug) = @_;

    print "DEBUG   : output=($output)\n" if ($debug == 1);

}

sub warn_message {

    my ($self, $output) = @_;

    print "WARNING : output=($output)\n";

}

sub error_message {

    my ($self, $output, $code) = @_;

    $code = 111 if !defined($code);

    print "ERROR   : output=($output) returncode=($code)\n";

}

1;
