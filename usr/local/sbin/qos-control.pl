#!/usr/bin/perl
#############################################################################################
#
#   Linux QoS Setting Tool
#       Copyright (C) 2012 MATSUMOTO, Ryosuke
#
#   This Code was written by matsumoto_r                 in 2012/04/08 -
#
#   Usage:
#       /usr/local/sbin/qos-control.pl
#
#############################################################################################
#
# Change Log
#
# 2012/04/08 matsumoto_r first release
#
#############################################################################################

use strict;
use warnings;
use lib "/usr/local/lib/myperl_lib";
use System::Base;
use File::Spec;
use File::Basename;
use Getopt::Long;

$| = 1;

our $VERSION    = '1.01';
our $SCRIPT     = basename($0);

our $QOS_INIT     = File::Spec->catfile("/etc", "rc.d", "init.d", "qos.init");
our $QOS_MODULE   = File::Spec->catfile("/usr", "local", "sbin", "qos.sh");
our $QOS_CONF_DIR = File::Spec->catfile("/etc", "sysconfig", "qos");

our $DIRECTION_LIST = {

    in  =>  {
                id          =>  1,
                direction   =>  "in",
                burst_rate  =>  5,
            },
    out =>  {
                id          =>  5001,
                direction   =>  "out",
                burst_rate  =>  10,
            },

};

our $PROTOCOL_LIST = {

    all     =>  {
                    id      =>  0,
                    port    =>  "",
                },
    ftp     =>  {   
                    id      =>  1,
                    port    =>  20,
                },
    ssh     =>  {   
                    id      =>  2,
                    port    =>  22,
                },
    smtp    =>  {
                    id      =>  3,
                    port    =>  25,
                },
    http    =>  {
                    id      =>  4,
                    port    =>  80,
                },
    pop3    =>  {
                    id      =>  5,
                    port    =>  110,
                },
    imap    =>  {
                    id      =>  6,
                    port    =>  143,
                },
    https   =>  {
                    id      =>  7,
                    port    =>  443,
                },
    imaps   =>  {
                    id      =>  8,
                    port    =>  993,
                },
    pop3s   =>  {
                    id      =>  9,
                    port    =>  995,
                },

};

our @TRAFFIC_LIST = qw(

    1
    2
    4
    8
    16

);

our @DEVICE_LIST = qw(

    eth0
    eth1
    eth2
    eth3

);


our $METHOD_LIST = {

    set     =>  \&set,
    clear   =>  \&clear,
    view    =>  \&view,

};

my ($server_ip, $client_ip, $server_port, $method, $protocol, $interface, $traffic, $direction);
our $TARGET_CLSID;

our $SYSTEM      = System::Base->new(
   debug           =>  0,
   info            =>  0,
   warn            =>  0,
   error           =>  1,
   irc_owner       =>  $SCRIPT,
   tool_name       =>  $SCRIPT,
   log_file        =>  "/tmp/$SCRIPT.log",
   pid_file        =>  "/tmp/$SCRIPT.pid",
   lock_file       =>  "/tmp/$SCRIPT.lock",
   syslog_type     =>  $SCRIPT,
);

GetOptions(

    "--method|m=s"      =>  \$method,
    "--ip|i=s"          =>  \$server_ip,
    "--src|s=s"         =>  \$client_ip,
    "--protocol|p=s"    =>  \$protocol,
    "--eth|e=s"         =>  \$interface,
    "--traffic|t=s"     =>  \$traffic,
    "--direction|d=s"   =>  \$direction,
    "--clsid|c=s"       =>  \$TARGET_CLSID,
    "--help"            =>  \&help,
    "--version"         =>  \&version,
);

$SIG{INT}  = sub { $SYSTEM->TASK_SIGINT };
$SIG{TERM} = sub { $SYSTEM->TASK_SIGTERM };

$SYSTEM->set_lock;
$SYSTEM->make_pid_file;

&help("not found method") if !defined $method;
&help("method is set but not found ip") if $method eq "set" && !defined $server_ip;
&help("method is set but not found direction") if $method eq "set" && !defined $direction;
&help("method is set but not found traffic") if $method eq "traffic" && !defined $traffic;
&help("method is view but not found ip") if $method eq "view" && !defined $server_ip;
&help("method is clear but not found ip") if $method eq "clear" && !defined $server_ip;
&help("method is clear but not found clsid") if $method eq "clear" && !defined $TARGET_CLSID;
&help("invalid ip: $server_ip") if defined $server_ip && $server_ip !~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/;
&help("invalid traffic: $traffic") if defined $traffic && !scalar(grep {$_ == $traffic} @TRAFFIC_LIST);
&help("invalid interface: $interface") if defined $interface && !scalar(grep {$_ eq $interface} @DEVICE_LIST);
&help("invalid protocol: $protocol") if defined $protocol && !exists $PROTOCOL_LIST->{$protocol};
&help("invalid direction: $direction") if defined $direction && !exists $DIRECTION_LIST->{$direction};

$client_ip    = (defined $client_ip)        ?   $client_ip          :   "";
$protocol     = (defined $protocol)         ?   $protocol           :   "all";
$interface    = (defined $interface)        ?   $interface          :   "eth0";
$server_ip    = (defined $server_ip)        ?   $server_ip          :   $SYSTEM->my_ip($interface);
$server_port  = ($protocol eq "all")        ?   ""                  :   ":$PROTOCOL_LIST->{$protocol}->{port}";
$TARGET_CLSID = (defined $TARGET_CLSID)     ?   $TARGET_CLSID       :   "0000";

$METHOD_LIST->{$method}->($server_ip, $protocol, $direction);

exit 0;

#############################################################################################
#
# Sub Routines
#
#############################################################################################

sub set {

    my ($ip, $protocol, $direction) = @_;

    $SYSTEM->info_record("method:set ip:$ip protocol:$protocol direction:$direction");
    print "*** old [$ip] settings ***\n";
    print "--------------------------\n";
    &view($ip);
    print "--------------------------\n";

    my $config_file = File::Spec->catfile($QOS_CONF_DIR, "qos-" . &get_clsid($ip, $protocol, $direction) . "." . $direction . "_" . $protocol);
    my $weight = $traffic / $DIRECTION_LIST->{$direction}->{burst_rate};

    my $config =<<CONFIG;
DIRECTION=$direction
DEVICE=$interface,100Mbit,10Mbit
RATE=${traffic}Mbit
WEIGHT=${weight}Mbit
PRIO=5
RULE=$server_ip$server_port,$client_ip
CONFIG

    print "\n";
    print "Setting ... ";
    $SYSTEM->file_write($config_file, "w", $config);
    sleep 1;
    $SYSTEM->exec_command("$QOS_INIT restart");
    print "OK\n\n";
    print "*** current [$ip] settings ***\n";
    print "------------------------------\n";
    &view($ip);
    print "------------------------------\n";
   
}

sub view {

    my $ip = shift;

    my $output = "";

    $SYSTEM->info_record("method:view ip:$ip");
    foreach my $protocol (keys %$PROTOCOL_LIST) {
        foreach my $direct (keys %$DIRECTION_LIST) {
            my $clsid = &get_clsid($ip, $protocol, $direct);
            my $config_file = File::Spec->catfile($QOS_CONF_DIR, "qos-" . $clsid . "." . $direct . "_" . $protocol);
            #print $config_file . "\n";
            next if !-f $config_file;
            my @config = $SYSTEM->file_read($config_file);
            $output .= "CLSID->$clsid\t";
            my %VIEW_LIST = ();
            grep    {
                        my ($key, $value) = split /=/, $_;
                        chomp($value);
                        my ($pkey, $pvalue, $skey, $svalue) = ();
                        if ($key eq "DEVICE") {
                            $VIEW_LIST{interface} = (split ",", $value)[0];
                        } elsif ($key eq "RATE") {
                            $value =~ s/Mbit/Mbps/g;
                            $VIEW_LIST{bandwidth} = $value;
                        } elsif ($key eq "RULE") {
                            my ($dst, $src) = split ",", $value;
                            $src = "nothing" if $src eq "";
                            $VIEW_LIST{server_ip_port} = $dst;
                            $VIEW_LIST{src_ip} = $src;
                        } elsif ($key eq "DIRECTION") {
                            $VIEW_LIST{direction} = $value;
                        }
                    } @config;
            $output .= sprintf("interface->%-10s direction->%-10s bandwidth->%-10s server_ip_port>%-20s src_ip->%-10s\n",
                    $VIEW_LIST{interface},
                    $VIEW_LIST{direction},
                    $VIEW_LIST{bandwidth},
                    $VIEW_LIST{server_ip_port},
                    $VIEW_LIST{src_ip});
        }
    }
    ($output ne "")     ?   print $output   :   print "nothing\n";
}

sub clear {

    my $ip = shift;

    $SYSTEM->info_record("method:clear ip:$ip clsid:$TARGET_CLSID");
    print "*** old [$ip] settings ***\n";
    print "--------------------------\n";
    &view($ip);
    print "--------------------------\n";

    print "\n";
    print "Setting Clear ... ";

    $SYSTEM->error_record("invalid clsid: $TARGET_CLSID") if $TARGET_CLSID !~ /[0-9]{4}/;
    my $config_file = File::Spec->catfile($QOS_CONF_DIR, "qos-" . $TARGET_CLSID . ".*");
    unlink glob($config_file);
    $SYSTEM->exec_command("$QOS_INIT restart");

    print "OK\n\n";
    print "*** current [$ip] settings ***\n";
    print "--------------------------\n";
    &view($ip);
    print "--------------------------\n";
}

sub get_clsid {

    my ($ip, $protocol, $direct) = @_;

    my $d_num = $DIRECTION_LIST->{$direct}->{id};
    my $p_num = $PROTOCOL_LIST->{$protocol}->{id};
    my $i_num = (split('\.', $ip))[3];

    return sprintf("%04d", $i_num + (255 * $p_num) + $d_num);
}

sub help {

    my $msg = shift;

    my @l_method    = keys %$METHOD_LIST;
    my @l_direction = keys %$DIRECTION_LIST;
    my @l_protocol  = keys %$PROTOCOL_LIST;

    print <<USAGE;

    usage: ./$SCRIPT --method|-m METHOD --ip|-i SERVER_IP --direction|-d DIRECTION --traffic|-t BANDWIDTH [--eth|-e INTREFACE] [--protocol|-p PROTOCOL] [--src|-s SRC_IP]

        -m, --method        set method                  (@l_method)
        -i, --ip            set server ip
        -d, --direction     set direction               (@l_direction)
        -t, --traffic       set traffic bandwidth Mbps  (@TRAFFIC_LIST)
        -e, --eth           set interface               (@DEVICE_LIST)
        -p, --protocol      set protocol                (@l_protocol)
        -s, --src           set src ip
        -c, --clsid         set clsid only clear method
        -h, --help          display this help and exit
        -v, --version       display version and exit

USAGE
    $SYSTEM->error_record("$msg") if defined $msg && $msg ne "help";
    exit 1;
}

sub version {

    print <<VERSION;

    Version: $SCRIPT-$VERSION

VERSION
    exit 1;

}
