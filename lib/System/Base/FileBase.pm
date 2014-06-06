#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::FileBase;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';


sub file_read {
    
    my ($self, $read_file) = @_;

    open(HFILE, "< $read_file") or $self->error_record("[System::Base::FileBase::file_read] can not open file: $read_file", 2, $self->error);
    my @contents = <HFILE>;
    close HFILE;

    return @contents;
}


sub file_write {

    my ($self, $write_file, $write_type, $write_str)  = @_;

    my $type = "";

    if ($write_type eq "a") {
        $type = ">>";
    } elsif ($write_type eq "w") {
        $type = ">";
    } else {
        $self->error_record("[System::Base::FileBase::file_write] invalid type: $write_type", 3, $self->error);
    }

    open(FH, "$type $write_file") or $self->error_record("[System::Base::FileBase::file_write] can not open file: $write_file", 4, $self->error);
    print FH "$write_str";
    close(FH);

}

1;
