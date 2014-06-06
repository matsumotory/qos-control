#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::PidBase;

our $VERSION = '0.01';

sub make_pid_file {

    my $self = shift;

    $self->error_record(__PACKAGE__."[make_pid_file] pid_file not setting property: " . $self->pid_file, 61, $self->error) if !defined $self->pid_file;

    my $pid_file = $self->pid_file;

    local *FILE;
    open FILE, "> $pid_file" or $self->error_record(__PACKAGE__." [make_pid_file] can not open file: $pid_file", 62, $self->error);
    flock FILE, LOCK_EX;
    print FILE "$$\n";
    close FILE;

    (-f $pid_file)  ?   $self->debug_record(__PACKAGE__." [make_pid_file] pid file create success: $pid_file", $self->debug)
                    :   $self->error_record(__PACKAGE__." [make_pid_file] pid file create faile: $pid_file", 63, $self->error); 
}


sub unlink_pid_file {

    my $self = shift;
    
    my $pid_file = $self->pid_file;

    unlink $pid_file if (-f $pid_file);

    (!-f $pid_file)  ?   $self->debug_record(__PACKAGE__." [unlink_pid_file] pid file unlink success: $pid_file", $self->debug)
                     :   $self->error_record(__PACKAGE__." [unlink_pid_file] pid file unlink faile: $pid_file", 64, $self->error); 
}

1;
