#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::LogBase;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';


sub log_write {

    my ($self, $output) = @_;

    my @lines = split /\n/, $output;
    foreach my $line (@lines) {
        $line =~ s/\n//;
        next if $line eq "";
        my $date = `date "+%h %d %H:%M:%S"`;
        chomp $date;
        open FH, ">> " . $self->log_file or $self->base_error_record(__PACKAGE__." [log_write] can not open file: " . $self->log_file, 11, $self->error);
        print FH $date . " " . $self->tool_name . "\[$$\]: " . $self->user_name . " $line\n";
        close FH;
    }
}

sub syslog_write {

    my ($self, $output, $type) = @_;

    my $pid     = $$;
    my @lines   = split(/\n/, $output);
    my $pri_fac = (defined $type)   ?   $type   :   $self->syslog_priority;

    foreach my $line (@lines) {
        $line =~ s/\n//;
        $line =~ s/\"/\\\"/g;
        $line =~ s/\'/\\\'/g;
        $line =~ s/\`/\\\`/g;
        next if $line eq "";
        my $retval = system "logger -p " . $pri_fac . " -t \"" . $self->syslog_type . "\[$pid\]\" \"" . $self->user_name . " $line\"";
        die "ERROR: syslog_write logger command. code=($retval)" if $retval != 0;
    }

}

sub change_log_line {

    my ($self, @array) = @_;

    my $log_line = "";

    foreach my $line (@array) {
        $log_line .= $line;
    }

    return $log_line;

}

1;
