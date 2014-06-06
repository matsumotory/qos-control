#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::MailBase;

use strict;
use Jcode;

our $VERSION = '0.01';

sub mail_send {

    my ($self, $message, $subject, $mailto) = @_;

    open(MAIL,"| sendmail -t");
    print MAIL "To: $mailto\n";
    print MAIL "From: " . $self->mailfrom . "\n";
    print MAIL "Subject: " . jcode($subject)->jis . "\n";
    print MAIL "MIME-Version: 1.0\n";
    print MAIL "Content-type: text/plain; charset=ISO-2022-JP\n";
    print MAIL "Content-Transfer-Encoding: 7bit\n\n";
    print MAIL jcode($message)->jis . "\n";
    close(MAIL);

    return 0;
}

1;
