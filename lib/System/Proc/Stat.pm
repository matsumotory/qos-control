#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################
package System::Proc::Stat;

use File::Spec;
use bigint;

our $VERSION = 0.01;

sub get_io_by_pid {

    my ($self, $pid) = @_;

    my $filename = File::Spec->catfile("/proc", $pid, "io");
    my %io_data = ();

    if (-f $filename) {
        my @lines = $self->file_read($filename);
        foreach my $line (@lines) {
            chomp($line);
            my ($key, $value) = split(/: /, $line);
            $io_data{$key} = $value if $key ne "" && $value ne "";
        }
    }
    return \%io_data;
}

sub get_pid_list {

    my $self = shift;

    opendir my $dh, '/proc';
    my @proc_pids = grep /^\d+$/, readdir($dh);
    closedir $dh;

    return @proc_pids;
}

sub get_cmdname_by_pid {

    my ($self, $pid) = @_;

    my $filename = File::Spec->catfile("/proc", $pid, "status");
    my %status_data = ();

    my @lines = $self->file_read($filename);
    foreach my $line (@lines) {
        chomp($line);
        $line =~ s/\t/ /g;
        $line =~ s/\s/ /g;
        my ($key, $value) = split(/: /, $line);
        $status_data{$key} = $value if $key ne "" && $value ne "";
    }

    return \%status_data;
}

sub get_exe_by_pid {

    my ($self, $pid) = @_;

    my $filename = File::Spec->catfile("/proc", $pid, "exe");
    my $exe_path = readlink($filename);

    $exe_path = '/' if !defined $exe_path;

    return $exe_path;
}


sub get_cwd_by_pid {

    my ($self, $pid) = @_;

    my $filename = File::Spec->catfile("/proc", $pid, "cwd");
    my $cwd_path = readlink($filename);

    $cwd_path = '/' if !defined $cwd_path;

    return $cwd_path;
}

sub get_domain {

    my ($self, $cwd) = @_;

    my $domain = "nothing";

    if ($cwd =~ /\/var\/www\/vhosts\/(.*)/) {
        $domain = $1;
        $domain =~ s/\/.*//g;
    }

    return $domain;
}

sub byte_to_bps {

    my ($self, $byte, $sec) = @_;

    my $bps = $byte * 8 / $sec;

    if ($bps > 1024 && $bps < (1024 * 1024)) {
        $bps = sprintf "%sKbps", $bps / 1024;
    } elsif ($bps > (1024 * 1024)) {
        $bps = sprintf "%sMbps", $bps / 1024 / 1024;
    } else {
        $bps = sprintf "%sbps", $bps;
    }   

    return $bps;
}
1;
