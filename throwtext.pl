##
## Put me in ~/.irssi/scripts, and then execute the following in irssi:
##
##       /load perl
##       /script load throwtext
##

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
use IO::Socket::INET;

use constant { PROTO_VERS => "V0.1" , PROTO_PORT => "4455" };

$VERSION = "0.0.1";
%IRSSI = (
    authors     => 'Cedric',
    contact     => 'https://github.com/cedricbu',
    name        => 'throwtext',
    description => 'Throw the text to be higlighted to a TCP connection',
    license     => 'GNU General Public License',
    url         => 'https://github.com/cedricbu/lonotify',
);

Irssi::settings_add_str('throwtext', 'pm_override', '');

sub throwText {
	my ($summary, $body) = @_;
	my $socket = new IO::Socket::INET (
		PeerAddr => 'localhost:' . PROTO_PORT,
		Proto => 'tcp'
	);
	die "Can't create a socket $!\n" unless $socket;

	$socket->send(pack("A*xA*xA*", PROTO_VERS, $summary, $body));

	$socket->close();
	

}
sub print_text_notify {
	my ($dest, $text, $message) = @_;

	return if (!$dest->{'server'} || !($dest->{level} & MSGLEVEL_HILIGHT));
	throwText($dest->{'target'}, $message);
}

sub message_private_notify {
    my ($server, $msg, $nick, $address) = @_;

    return if (!$server);

    $msg = Irssi::settings_get_str('pm_override') if Irssi::settings_get_str('pm_override');
    throwText( "Private message from ".$nick, $msg);
}

sub throwTextTest {
	# data - contains the parameters for /HELLO
	# server - the active server in window
	# witem - the active window item (eg. channel, query)
	#         or undef if the window is empty
	my ($data, $server, $witem) = @_;
	$data = "Throwtext is loaded" unless $data;
	print "throwning text: $data";
	throwText("IRSSI throwText", $data);
	print "text thrown";
}


Irssi::signal_add('print text', 'print_text_notify');
Irssi::signal_add('message private', 'message_private_notify');
Irssi::command_bind('throwtext', 'throwTextTest');
print "throwText plugin loaded.";
throwText("throwText", "Loaded");
