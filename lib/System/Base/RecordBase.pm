#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::RecordBase;

use strict;

our $VERSION = '0.01';



sub info_record {

    my ($self, $output, $info_flag) = @_;

    my $info_msg = "INFO: $output";
    $info_flag = $self->info if !defined $info_flag;

    $self->info_message($info_msg, $info_flag);
    $self->log_write($info_msg);

    
}

sub debug_record {

    my ($self, $output, $debug_flag) = @_;

    my $debug_msg = "DEBUG: $output";
    $debug_flag = $self->debug if !defined $debug_flag;

    $self->debug_message("$output", $debug_flag);
    $self->log_write($debug_msg);

}

sub warn_record {

    my ($self, $output, $warn_flag) = @_;

    my $warn_msg = "WARN: $output";
    $warn_flag = $self->warn if !defined $warn_flag;

    $self->warn_message("$output", $warn_flag);
    $self->syslog_write($warn_msg);
    $self->log_write($warn_msg);

}

sub error_record {

    my ($self, $output, $code, $output_flag) = @_;

    $code = 1 if !defined $code;
    $output_flag = $self->error if !defined $output_flag;

    my $error_msg = "ERROR: $output code=($code)";

    $self->exit_code($code);
    $self->error_message("$error_msg", $code) if $output_flag;
    $self->syslog_write("$error_msg", "local0.notice");
    $self->log_write("$error_msg");

    exit($code);

}

sub error_record_not_exit {

    my ($self, $output, $code, $output_flag) = @_;

    $code = 1 if !defined $code;
    $output_flag = $self->error if !defined $output_flag;

    my $error_msg = "ERROR: $output code=($code)";

    $self->exit_code($code);
    $self->error_message("$error_msg", $code) if $output_flag;
    $self->syslog_write("$error_msg", "local0.notice");
    $self->log_write("$error_msg");

}

sub base_error_record {

    my ($self, $output, $code, $output_flag) = @_;

    my $error_msg = "ERROR: $output code=($code)";

    $self->exit_code($code);
    $self->error_message("$error_msg", $code) if defined($output_flag) && $output_flag == 1;
    $self->syslog_write("$error_msg");

    exit($code);

}

1;
