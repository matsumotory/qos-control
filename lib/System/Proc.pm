#!/usr/bin/perl
package System::Proc;

use strict;
use warnings;
use Sys::Hostname;
use base "System::Base";
use base qw(

    System::Proc::Stat

);

$ENV{'IFS'}     = '' if $ENV{'IFS'};
$ENV{'PATH'}    = '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin';
$ENV{'LC_TIME'} = 'C';
umask(022);

sub new {

    my ($class, %args) = @_;

    my $self =  bless {

        # Base.pm properties
        debug               =>  (exists $args{debug})            ? $args{debug}             :   0,
        info                =>  (exists $args{info})             ? $args{info}              :   0,
        warn                =>  (exists $args{warn})             ? $args{warn}              :   0,
        error               =>  (exists $args{error})            ? $args{error}             :   0,
        irc_owner           =>  (exists $args{irc_owner})        ? $args{irc_owner}         :   'System',
        irc_channel         =>  (exists $args{irc_channel})      ? $args{irc_channel}       :   '#TEST:*.jp',
        irc_server          =>  (exists $args{irc_server})       ? $args{irc_server}        :   '256.256.256.256',
        log_file            =>  (exists $args{log_file})         ? $args{log_file}          :   "/tmp/operation_tool-$ENV{USER}.log",
        tool_name           =>  (exists $args{tool_name})        ? $args{tool_name}         :   'operation_tool',
        syslog_type         =>  (exists $args{syslog_type})      ? $args{syslog_type}       :   'operation',
        syslog_priority     =>  (exists $args{syslog_priority})  ? $args{syslog_priority}   :   'local3.notice',
        mailfrom            =>  (exists $args{mailfrom})         ? $args{mailfrom}          :   'operation@'.hostname(),
        pid_file            =>  (exists $args{pid_file})         ? $args{pid_file}          :   "/tmp/operation_tool-$ENV{USER}.pid",
        lock_file           =>  (exists $args{lock_file})        ? $args{lock_file}         :   "/tmp/operation_tool-$ENV{USER}.lock",
        user_name           =>  (exists $args{user_name})        ? $args{user_name}         :   $ENV{USER},
        lock_fd             =>  undef,
        command             =>  undef,
        already_running     =>  0,

    }, $class;

    $self->debug_record(__PACKAGE__." [new] executed.", $self->{info});
    $self->initialization;

    return $self;
}

sub initialization {

    my $self = shift;

}

1;
