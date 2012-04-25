#!/usr/bin/perl
#############################################################################################
#
# package
#
#############################################################################################

package System::Base::IrcBase;

use strict;
use warnings;
use Jcode;
use IO::Socket;

our $VERSION = '0.01';

sub irc_write {

    my ($self, $output) = @_;

    &irc_main($output); 
}

sub irc_main {

    my ($self, $output) = @_;

    $| = 1;
    
    my $sleep       = 1;
    my $port        = 6667;
    my $channel     = jcode($self->irc_channel)->jis;
    my $irc_socket  = &irc_connect($self->irc_server, $port, $self->irc_owner);

    my @lines = split /\n/, $output;
    foreach my $line (@lines) {
        chomp($line);
        print $irc_socket "privmsg $channel :". jcode($line)->jis ."\r\n";
        sleep($sleep);
    }
    
    print $irc_socket "quit\r\n";
    $irc_socket->close();
    
}

sub irc_connect {

    my ($server, $port, $nickname) = @_;

    my $IRC = new IO::Socket::INET(

                                    PeerAddr => $server,
                                    PeerPort => $port,
                                    Proto    => 'tcp',
                                    Timeout  => 5,

    ) or die "ERROR: do not connect\n";

    print $IRC "user $nickname 8 * :system.base.ircbase.pm\r\n";

    my $nick_check = 0;
    my $allowchr = "2345678abcdefhkmnprstuvwxyzABCDEFGHJKLMNQRSTUVWXYZ";

    while($nick_check == 0) {

        print $IRC "nick $nickname\r\n";

        while (my $input = <$IRC>) {
            &debug($input);

            if ($input =~ / 004 /) {
                $nick_check = 1;
                last;
            } elsif ($input =~ / 433 /) {
                $nickname = substr($nickname, 0, 8) . substr($allowchr, int(rand(length($allowchr))), 1);
                last;
            }
        }
    }

    return $IRC;
}

1;
