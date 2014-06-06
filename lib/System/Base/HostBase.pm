#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################
# 2010-6-18 ogata   eth gentei wo yameta.  bond mo ok desu.

package System::Base::HostBase;

use strict;
use Sys::Hostname;

our $VERSION = '0.01';


sub my_ip {

    my ($self, $if) = @_;

    my $myip = ($self->exec_command("ip addr | awk '(\$7 ~ /$if/) { print \$2 }' | sed -e 's/\\/.*\$//' 2>&1"))[0];
    $self->error_record(__PACKAGE__." [my_ip] invalid my_ip: $myip", "123", $self->error) if $myip !~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/;

    return $myip;
}

sub my_host {

    my $self = shift;

    return hostname();
}

sub my_host_check {

    my ($self, @hosts) = @_;

    foreach my $check_host (@hosts) {
        return 0 if $check_host eq $self->my_host;
    }

    return 1;
}

1;
