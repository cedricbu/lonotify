#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use IO::Socket::INET;
use constant { PROTO_VERS => "V0.1" , PROTO_PORT => "4455" };

my %SCRIPT = (
	name => 'throwtext',
	author => 'Cedric <gaspotrash@gmail.com>',
	version => '0.0',
	license => 'GPL3',
	desc => 'Forward notification to a localhost port',
);
my %OPTIONS_DEFAULT = (
	'enabled' => ['on', "Turn script on or off"],
	'show_highlights' => ['on', 'Notify on highlights'],
	'show_priv_msg' => ['on', 'Notify on private messages'],
	'annon_priv_msg' => ['off', 'When receiving private message notifications, hide the actual message text'],
	'verbose' => ['1', 'Verbosity level (0 = silently ignore any errors, 1 = display brief error, 2 = display full server response)'],
);
my %OPTIONS = ();
my $WEECHAT_VERSION;

# Enable for debugging
my $DEBUG = 0;


# INIT
# Register script and initialize config
weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");

# Setup hooks
#weechat::config_set_plugin("pm_override", "");
weechat::config_set_desc_plugin("pm_override", "if set, replaces private messages");
weechat::hook_print("", "notify_message", "", 1, "throwText_highlight_hook", "");
weechat::hook_print("", "notify_private", "", 1, "throwText_private_hook", "");
weechat::hook_command("throwText",
    "send notification",
	"<text>",
	"text: notification text to send",
	"",
    "throwText_cmd", 
    "");


sub throwText {
	my ($summary, $body) = @_;
	my $socket = new IO::Socket::INET (
		PeerAddr => 'localhost:' . PROTO_PORT,
		Proto => 'tcp'
	);
	return weechat::WEECHAT_RC_ERROR unless $socket;

	$socket->send(pack("A*xA*xA*", PROTO_VERS, $summary, $body));

	$socket->close();
    return weechat::WEECHAT_RC_OK;
}

sub throwText_cmd {
    my ($data, $buffer, $args) = @_;

    return weechat::WEECHAT_RC_OK unless $args;
    return throwText("IRC Throw Text:", $args);
}

# Hooks
sub throwText_highlight_hook {
	my ($data, $buffer, $date, $tags, $displayed, $highlight, $prefix, $message) = @_;

	return weechat::WEECHAT_RC_OK unless $highlight;

    my $header = sprintf("Message from %s on %s", 
        $prefix,
        weechat::buffer_get_string($buffer, "short_name"));

	return throwText($header, $message);
}


sub throwText_private_hook {
	my ($data, $buffer, $date, $tags, $displayed, $highlight, $prefix, $message) = @_;

    my $name = weechat::buffer_get_string($buffer, "short_name");

    if ( weechat::config_get_plugin("pm_override") ) {
        $message =  weechat::config_get_plugin("pm_override") ;
    }

    return throwText( "Private message from $name", $message);

}

throwText("$SCRIPT{name} plugin", "Loaded");

__END__
