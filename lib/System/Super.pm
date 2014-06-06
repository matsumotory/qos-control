#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Super;
use base qw(Class::Accessor);


sub TASK_SIGINT {

    my $self = shift;

    $self->info_record(__PACKAGE__." [TASK_SIGINT] catch SIGINT.", $self->info);
    $self->error_record(__PACKAGE__." [TASK_SIGINT] call DESTROY.", 51, $self->error);

}

sub TASK_SIGTERM {

    my $self = shift;

    $self->info_record(__PACKAGE__." [TASK_SIGTERM] catch SIGTERM.", $self->info);
    $self->error_record(__PACKAGE__." [TASK_SIGTERM] call DESTROY.", 52, $self->error);

}

sub TASK_SIGCHLD {

    my $self = shift;

    $self->info_record(__PACKAGE__." [TASK_SIGCHLD] catch SIGCHLD.", $self->info);
    $self->error_record(__PACKAGE__." [TASK_SIGCHLD] call DESTROY.", 53, $self->error);

}

sub TASK_SIGALRM {

    my $self = shift;

    $self->info_record(__PACKAGE__." [TASK_SIGALRM] catch SIGALRM.", $self->info);
    $self->error_record(__PACKAGE__." [TASK_SIGALRM] call DESTROY.", 54, $self->error);

}

1;
