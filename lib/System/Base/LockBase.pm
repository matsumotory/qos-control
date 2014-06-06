#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::LockBase;

use IO::File;
use Fcntl qw(:DEFAULT :flock);

our $VERSION = '0.01';

sub set_lock {

    my $self = shift;

    my $lock_file = $self->lock_file;

    my $fd = IO::File->new($lock_file, O_RDONLY | O_CREAT) or $self->error_record(__PACKAGE__." [set_lock] can not open file: $lock_file", 23, $self->error);

    if (!flock $fd, LOCK_EX | LOCK_NB) {
        $fd->close;
        undef $fd;
        $self->error_record(__PACKAGE__." [set_lock] can not flock file: $lock_file. " . $self->tool_name . " is already running", 24, $self->error);
    }

    $self->lock_fd($fd);
    $self->already_running(1);

    (-f $lock_file) ?   $self->debug_record(__PACKAGE__." [set_lock] lock file create success. lock start....", $self->debug)
                    :   $self->error_record(__PACKAGE__." [set_lock] lock file create fail.", 25, $self->error);
}

sub set_unlock {

    my $self = shift;

    if (defined $self->lock_fd) {
        close $self->lock_fd;
        $self->lock_fd(undef);
    }

    unlink $self->lock_file;

    (!-f $self->lock_file)    ?   $self->debug_record(__PACKAGE__." [set_unlock] lock file unlink success. lock finish.", $self->debug)
                              :   $self->error_record(__PACKAGE__." [set_unlock] lock file unlink fail.", 26, $self->error);
}

1;
