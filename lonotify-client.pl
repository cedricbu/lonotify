#!/usr/bin/perl
use warnings;
use strict;

use IO::Socket::INET;
use Getopt::Std;

use feature qw(say);

## GLOBALS & default values ###
my $VERSION = "0.0.1"; # script version 
my $DEBUG = 0 ; 

### Standard Opt first : Help and version
sub VERSION_MESSAGE {
	print "$0 version $VERSION\n";
	exit 0;
}
sub HELP_MESSAGE {
	print <<EOM;
Sends a message via Throwtext
EOM
	exit 0;
}


use constant { PROTO_VERS => "V0.1" , PROTO_PORT => "4455" };


# First : Options
my %opts;
getopts('D:ht:m:', \%opts);
HELP_MESSAGE() if defined( $opts{'h'} );

$opts{'t'} = "Default title" unless defined $opts{'t'};
$opts{'m'} = "Default message" unless defined $opts{'m'};

my $data = pack("A*xA*xA*", PROTO_VERS, $opts{'t'}, $opts{'m'});

say "DBG: $data";

# auto-flush on socket
$| = 1;

my $socket;

$socket = new IO::Socket::INET (
	PeerAddr => 'localhost:' . PROTO_PORT,
	Proto => 'tcp'
);
die "Cannot create socket: $!\n" unless $socket;
print "Connected\n";

$socket->send($data);

$socket->close();
	
