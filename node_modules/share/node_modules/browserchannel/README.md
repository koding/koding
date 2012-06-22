A [BrowserChannel](http://closure-library.googlecode.com/svn/trunk/closure/goog/net/browserchannel.js) server.

**tldr;** Its like socket.io, but it scales better and it has fewer bugs. It
just does long polling. It doesn't support websockets and doesn't work cross-domain.

BrowserChannel is google's version of [socket.io](http://socket.io) from when they first put
chat in gmail. Unlike socket.io, browserchannel provides much better guarantees about message
delivery and state. It has better reconnection logic and error handling. With browserchannel,
**you know whats going on**.

[![Build Status](https://secure.travis-ci.org/josephg/node-browserchannel.png)](http://travis-ci.org/josephg/node-browserchannel)

node-browserchannel:

- Is compatible with the closure library's browserchannel implementation
- Is super thoroughly tested
- Works in IE5.5+, iOS, Safari, Chrome, Firefox, and probably others.
- Works in any network environment (incl. behind buffering proxies)

---

# Use it

    # npm install browserchannel

Browserchannel is implemented as connect middleware. Here's an echo server:

```coffeescript
browserChannel = require('browserchannel').server
connect = require 'connect'

server = connect(
  connect.static "#{__dirname}/public"
  browserChannel (session) ->
    console.log "New session: #{session.id} from #{session.address} with cookies #{session.headers.cookie}"

    session.on 'message', (data) ->
      console.log "#{session.id} sent #{JSON.stringify data}"
      session.send data

    session.on 'close', (reason) ->
      console.log "Session #{session.id} disconnected (#{reason})"
      
    # This tells the session to stop trying to connect
    session.stop()
    
    # This just kills the session.
    session.abort()
).listen(4321)

console.log 'Echo server listening on localhost:4321'
```

The client emulates the [websocket API](http://dev.w3.org/html5/websockets/). Here is a simple client:

```coffeescript
{BCSocket} = require 'browserchannel'

socket = new BCSocket 'http://localhost:4321/channel'
socket.onopen = ->
  socket.send {hi:'there'}
socket.onmessage = (message) ->
  console.log 'got message', message

# later...
socket.close()
```

... Or from a website:

```html
<html><head>
<script src='/channel/bcsocket.js'></script>
<script>
socket = new BCSocket('/channel');
socket.onopen = function() {
  socket.send({hi:'there'});
  socket.close();
};
socket.onmessage = function(message) {
  // ...
};
</script>
```

You can also ask the client to automatically reconnect whenever its been disconnected. - Which is
super useful.

```coffeescript
{BCSocket} = require 'browserchannel'
socket = new BCSocket 'http://localhost:4321/channel', reconnect:true
socket.onopen = ->
  socket.send "I just connected!"
```

---

# Caveats

- It doesn't do RPC.
- It doesn't work in cross-origin environments. Put it behind 
  [nginx](http://nginx.net/) or [varnish](https://www.varnish-cache.org/) if you aren't using nodejs
  to host your whole site.
- Currently there's no websocket support. So, its higher bandwidth than socket.io running on modern
  browsers.

---

### License

Licensed under the standard MIT license:

Copyright 2011 Joseph Gentle.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
