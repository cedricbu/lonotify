#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use vars qw($VERSION);

use IO::Socket::INET;
use IO::Select;
use Net::DBus qw(:typing);
use HTML::Entities;
use Getopt::Std;

use constant { PROTO_PORT => "4455" };


##### PROTOCOL
# tcp, receive only 1 message
#  "$PROTO_VERS\000$PROTO_VERS_DEPENDANT"
#
#  PROTO_VERS == V0.1
#     $PROTO_VERS_DEPENDANT == "$SUMMARY\000$BODY"
#  Notes :
#    - can't do UDP because it's meant for ssh reverse port forwarding
 
# auto-flush on socket
$| = 1;

# Should we encode before sending to dbus notification ?
#  might be safer if yes, but then some notifier do not seem to decode
my $encode = 0;



sub send_notification {
    my ($app_name, $replace_id, $icon, $summary, $body, $actions, $hints, $expire) = @_;
    say "DBG: send_notification args:";
    say @_;
    say "DBG: end of args";
    my $bus = Net::DBus->session;
    return if (!$bus);
    my $svc = $bus->get_service("org.freedesktop.Notifications");
    my $obj = $svc->get_object("/org/freedesktop/Notifications");

    # Make the body entity-safe.
    $encode && encode_entities($body);

    $obj->Notify($app_name,          # App name
                 $replace_id,        # replace ID
                 $icon,              # icon
                 $summary,           # summary
                 $body,              # body
                 $actions,           # Actions
                 $hints,             # hints
                 $expire);           # expiration time
}
sub notify_v01 {
	my ($summary, $body) = split ('\0', $_[0]);
	say "DBG: notify_v01: calling with $summary, $body";
	send_notification("NetNotify",        # App name
                 0,                  # replace ID
                 "",                 # icon
                 $summary,           # summary
                 $body,              # body
                 [],                 # Actions
                 {},                 # hints
                 5000);
}
sub notify_error {
	say "DBG: notify_error was called";
	send_notification("NetNotify",        # App name
                 0,                  # replace ID
                 "",                 # icon
                 "netnotify error",  # summary
                 "received a non-handled message",
                 [],                 # Actions
                 {},                 # hints
                 5000);

}

sub daemonize {
	say "Daemonizing";
	use POSIX;
	POSIX::setsid or die "setsid: $!";
	my $pid = fork ();
	if ($pid < 0) {
		die "fork: $!";
	} elsif ($pid) {
		exit 0;
	}
	chdir "/";
	umask 0;
	foreach (0 .. (POSIX::sysconf (&POSIX::_SC_OPEN_MAX) || 1024)) { 
		POSIX::close $_ 
	}
	open (STDIN, "</dev/null");
	open (STDOUT, ">/dev/null");
	open (STDERR, ">&STDOUT");
}

## VARS
my $listen;  ## main listening socket
my $select;  ## Select socket
my %opts;    ## argument hash

## Arguments
getopts('d', \%opts);

# -d : daemonize (will redirect outputs to /dev/null)

daemonize() if defined( $opts{'d'} ) ;


 
# creating a listening socket
$listen = new IO::Socket::INET (
    LocalHost => 'localhost',
    LocalPort => PROTO_PORT,
    Proto => 'tcp',
    Listen => 5,
    ReuseAddr => 1
);
die "cannot create socket: $!\n" unless $listen;
print "server waiting for client connection on port " . $listen->sockport() . "\n";
 

# Adds the listening socket on the Select
$select = new IO::Select();
$select->add($listen);

while(1)
{
	foreach my $so ( $select->can_read() ) {
		if($so == $listen) {
			# new connection read
			# accept & add it to the select
			my $client = $listen->accept();

			$select->add($client);
		} else {
			# existing client read
			my $recv;
			$so->recv($recv, 2048);
			say "DBG: Received \n----\n $recv \n----";
			say "DBG: Unpacking";
			my ($version, $data) = split ('\0', $recv, 2);
			if ($version eq "V0.1") {
				say "DBG: calling v01 : $version";
				notify_v01($data);
			} else {
				say "DBG: calling error : $version";
				notify_error();
			}
			$select->remove($so);
			$so->close();
		}
	}
}
$select->remove($listen); 
$listen->close();
