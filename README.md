# lonotify
An efficient remote notification system, primarily designed to be used as an irssi client notification

## History

After weeks of searching and trying tools to allow IRSSI notifications over SSH, I did not find anything suitable. So I gave up and built one from scratch.
I called it lonotify because it's made to only listen on loopback address.

## How it works

### Server
**lonotifyd.pl**

Listens on loopback interface, port `4455`, for a message. It listens for TCP only, because SSH tunneling works only on TCP. 
Upon reception of a message, the server will forward it to the d-bus notification daemon.

Use `-d` option to daemonize it.

### Clients
The clients will simply connect on loopback port `4455`, and send then notification. The SSH connection will redirect that to the local machine's port 4455.

**throwtext.pl** : a IRSSI plugin

It provides the following :
   - command `throwtext` : to simply send text to lonotifyd.
   - option `pm_override` : sometimes, you want privacy. This string will replace any private message you receive.

**lonotify-client.pl** : a CLI.

  use as : 
```
$ lonotify-client.pl -t "title" -m "body of the message"
```

**weechat/throwtext.pl** : a weechat plugin

It provides the following:
    - command `/throwtext` : to simply send text to lonotifyd.
    

## Benefits

- It can work through NAT, and will not mind if you are using in a terminal multiplexer (e.g.: screen, tmux). All it needs is a SSH connection.

- Efficient : each notification requires little data sent through.

- Easy setup, little configuring required

- Low attack surface: only a local attacker either on the local machine or remote IRSSI machine could benefit of this service. The messages are protected by the ssh connection.

## Installation

1. Run the server on your local computer: `$ lonotifyd.pl -d`
2. SSH with port tunneling with the `-R` command with `$ ssh -R 4455:localhost:4455 <remote-location>`
3. On the IRSSI machine, put the `throwtext.pl` plugin in the IRSSI script directory (e.g.: `~/.irssi/scripts/`)
4. In IRSSI, start the throwtext plugin, using `/script load throwtext`

## Notes

- If you use a multiplexer and detach, the plugin will fail and will be unloaded by irssi when the SSH connection exit. You will have to reload it once you re-attach the multiplexer.
- If the connection crashes unexpectedly, the port 4455 will remain hanging for several minutes on the remote machine, and the port can not be reused for a few minutes. You will have to re-ssh again after a few minutes, when the port is freed.

## TODO
- Correct the stuck port on connection drop
- add optional stuff to the protocol, such as compression, icons, etc.i
- test text
