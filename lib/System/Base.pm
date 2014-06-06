#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base;

use strict;
use Sys::Hostname;

use base "System::Super";

use base qw(
    System::Base::FileBase
    System::Base::IrcBase
    System::Base::MailBase
    System::Base::CommandBase
    System::Base::LogBase
    System::Base::RecordBase
    System::Base::MessageBase
    System::Base::HostBase
    System::Base::PidBase
    System::Base::LockBase
    System::Base::CheckBase
);

__PACKAGE__->mk_accessors(qw(
    debug           
    info            
    warn            
    error           
    irc_owner       
    irc_channel     
    irc_script      
    log_file        
    tool_name       
    syslog_type     
    syslog_priority 
    mailfrom        
    pid_file        
    lock_file       
    user_name       
    lock_fd         
    already_running 
    exit_code
));

our $VERSION = '0.01';

$ENV{'IFS'}     = '' if $ENV{'IFS'};
$ENV{'PATH'}    = '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin';
$ENV{'LC_TIME'} = 'C';
umask(022);

sub new {

    my ($class, %args) = @_;

    my $self = bless {

        debug               =>  (exists $args{debug})            ? $args{debug}             :   0,
        info                =>  (exists $args{info})             ? $args{info}              :   0,
        warn                =>  (exists $args{warn})             ? $args{warn}              :   0,
        error               =>  (exists $args{error})            ? $args{error}             :   0,
        irc_owner           =>  (exists $args{irc_owner})        ? $args{irc_owner}         :   'Script-Monitor',
        irc_channel         =>  (exists $args{irc_channel} )     ? $args{irc_channel}       :   '#TEST:*.jp',
        irc_server          =>  (exists $args{irc_server})       ? $args{irc_server}        :   '256.256.256.256',
        log_file            =>  (exists $args{log_file})         ? $args{log_file}          :   "/tmp/operation-tool-$ENV{USER}.log",
        tool_name           =>  (exists $args{tool_name})        ? $args{tool_name}         :   'operation-tool',
        syslog_type         =>  (exists $args{syslog_type})      ? $args{syslog_type}       :   'operation-system',
        syslog_priority     =>  (exists $args{syslog_priority})  ? $args{syslog_priority}   :   'local3.notice',
        mailfrom            =>  (exists $args{mailfrom})         ? $args{mailfrom}          :   'system@'.hostname(),
        pid_file            =>  (exists $args{pid_file})         ? $args{pid_file}          :   "/tmp/operation-tool-$ENV{USER}.pid",
        lock_file           =>  (exists $args{lock_file})        ? $args{lock_file}         :   "/tmp/operation-tool-$ENV{USER}.lock",
        user_name           =>  (exists $args{user_name})        ? $args{user_name}         :   $ENV{USER},
        lock_fd             =>  undef,
        already_running     =>  0,
        exit_code           =>  0,    

    }, $class;

    $self->debug_record(__PACKAGE__." [new] executed.", $self->debug);
    $self->initialization;

    return $self;
}


sub initialization {

    my $self = shift;

}

sub DESTROY {

    my $self = shift;

    my $unlink_log_size = 1000000;

    $self->debug_record(__PACKAGE__." [DESTROY] execute unlink_pid_file and set_unlock", $self->debug);

    if ($self->{already_running} == 1) {
        $self->unlink_pid_file;
        $self->set_unlock;
        my $log_size = -s $self->log_file;
        unlink $self->log_file if $log_size > $unlink_log_size;
    }

    exit $self->exit_code;
}
