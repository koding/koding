# This is a little wrapper around browserchannels which exposes something thats compatible
# with the websocket API. It also supports automatic reconnecting, and some other goodies.
#
# You can use it just like websockets:
#
#     var socket = new BCSocket '/foo'
#     socket.onopen = ->
#       socket.send 'hi mum!'
#     socket.onmessage = (message) ->
#       console.log 'got message', message
# 
# ... etc. See here for specs:
# http://dev.w3.org/html5/websockets/
#
# I've also added:
#
# - You can reconnect a disconnected socket using .open().
# - .send() transparently works with JSON objects.
# - .sendMap() works as a lower level sending mechanism.
# - The second argument can be an options argument. Valid options:
#   - **appVersion**: Your application's protocol version. This is passed to the server-side
#     browserchannel code, in through your session handler as `session.appVersion`
#   - **prev**: The previous BCSocket object, if one exists. When the socket is established,
#     the previous bcsocket session will be disconnected as we reconnect.
#   - **reconnect**: Tell the socket to automatically reconnect when its been disconnected.
#   - **failFast**: Make the socket report errors immediately, rather than trying a few times
#     first.

goog.provide 'bc.BCSocket'

goog.require 'goog.net.BrowserChannel'
goog.require 'goog.net.BrowserChannel.Handler'
goog.require 'goog.net.BrowserChannel.Error'
goog.require 'goog.net.BrowserChannel.State'

# Closure uses numerical error codes. We'll translate them into strings for the user.
errorMessages = {}
errorMessages[goog.net.BrowserChannel.Error.OK] = 'Ok'
errorMessages[goog.net.BrowserChannel.Error.LOGGED_OUT] = 'User is logging out'
errorMessages[goog.net.BrowserChannel.Error.UNKNOWN_SESSION_ID] = 'Unknown session ID'
errorMessages[goog.net.BrowserChannel.Error.STOP] = 'Stopped by server'

# All of these error messages basically boil down to "Something went wrong - try again". I can't
# imagine using different logic on the client based on the error here - just keep reconnecting.

# The client's internet is down (ping to google failed)
errorMessages[goog.net.BrowserChannel.Error.NETWORK] = 'General network error'
# The server could not be contacted
errorMessages[goog.net.BrowserChannel.Error.REQUEST_FAILED] = 'Request failed'

# This error happens when the client can't connect to the special test domain. In my experience,
# this error happens normally sometimes as well - if one particular connection doesn't
# make it through during the channel test. This will never happen with node-browserchannel anyway
# because we don't support the network admin blocking channel.
errorMessages[goog.net.BrowserChannel.Error.BLOCKED] = 'Blocked by a network administrator'

# We got an invalid response from the server
errorMessages[goog.net.BrowserChannel.Error.NO_DATA] = 'No data from server'
errorMessages[goog.net.BrowserChannel.Error.BAD_DATA] = 'Got bad data from the server'
errorMessages[goog.net.BrowserChannel.Error.BAD_RESPONSE] = 'Got a bad response from the server'

`/** @constructor */`
BCSocket = (url, options) ->
  self = this

  # Url can be relative or absolute. (Though an absolute URL in the browser will have to match
  # same origin policy)
  url ||= 'channel'

  # Websocket urls are specified as ws:// or wss://. Replace the leading ws with http.
  url.replace /^ws/, 'http' if url.match /:\/\//

  options ||= {}

  # Using websockets you can specify an array of protocol versions or a protocol version string.
  # All that stuff is ignored.
  options = {} if goog.isArray options or typeof options is 'string'

  reconnectTime = options['reconnectTime'] or 3000

  # The channel starts CLOSED. When connect() is called, the channel moves into the CONNECTING
  # state. If it connects, it moves to OPEN. If an error occurs (or an error occurs while the
  # connection is connected), the socket moves to 'CLOSED' again.
  #
  # At any time, you can call close(), which disconnects the socket.

  setState = (state) -> # This is convenient for logging state changes, and increases compression.
    self.readyState = self['readyState'] = state

  setState @CLOSED

  # The current browserchannel session we're connected through.
  session = null

  # When we reconnect, we'll pass the SID and AID from the previous time we successfully connected.
  lastSession = options.prev

  # A handler is used to receive events back out of the session.
  handler = new goog.net.BrowserChannel.Handler()

  handler.channelOpened = (channel) ->
    lastSession = session
    setState BCSocket.OPEN
    self['onopen']?()

  # If there's an error, the handler's channelError() method is called right before channelClosed().
  # We'll cache the error so a 'disconnect' handler knows the disconnect reason.
  lastErrorCode = null

  # This is called when the session has the final error explaining why its closing. It is
  # called only once, just before channelClosed(). It is not called if the session is manually
  # disconnected.
  handler.channelError = (channel, errCode) ->
    message = errorMessages[errCode]
    #console?.error 'channel error', errCode, message
    lastErrorCode = errCode
    setState BCSocket.CLOSING
    # I'm not 100% sure what websockets do if there's an error like this. I'm going to assume it has the
    # same behaviour as browserchannel - that is, onclose() is always called if a connection closes, and
    # onerror is called whenever an error occurs.
    self['onerror']? message, errCode

  reconnectTimer = null

  handler.channelClosed = (channel, pendingMaps, undeliveredMaps) ->
    #console.error 'channelClosed', self.readyState

    # Hm.
    #
    # I'm not sure what to do with this potentially-undelivered data. I think I'll toss it
    # to the emitter and let that deal with it.
    #
    # I'd rather call a callback on send(), like the server does. But I can't, because
    # browserchannel's API isn't rich enough.

    # Should handle server stop
    return if self.readyState is BCSocket.CLOSED

    # And once channelClosed is called, we won't get any more events from the session. So things like send()
    # should throw exceptions.
    session = null

    message = if lastErrorCode then errorMessages[lastErrorCode] else 'Closed'

    setState BCSocket.CLOSED

    # This whole method is surrounded in a try-catch block which silently discards exceptions.
    # Thats really annoying for debugging. I'll make sure errors get logged here, at least.
    try
      self['onclose']? message, pendingMaps, undeliveredMaps
    catch e
      console?.error e.stack

    # If the error message is STOP, we won't reconnect. That means the server has explicitly requested
    # the client give up trying to reconnect due to some error.
    #
    # The error code will be 'OK' if close() was called on the client.
    if options['reconnect'] and lastErrorCode not in [goog.net.BrowserChannel.Error.STOP, goog.net.BrowserChannel.Error.OK]
      #console.warn 'rc'
      # If the session ID is unknown, that means the session has timed out. We can reconnect immediately.
      time = if lastErrorCode is goog.net.BrowserChannel.Error.UNKNOWN_SESSION_ID then 0 else reconnectTime

      clearTimeout reconnectTimer
      reconnectTimer = setTimeout reconnect, time

    # make sure we don't reuse an old error message later
    lastErrorCode = null

  # Messages from the server are passed directly.
  handler.channelHandleArray = (channel, message) ->
    # Exceptions thrown in channelHandleArray aren't handled at all.
    self['onmessage']? message

  # This reconnects if the current session is null.
  reconnect = ->
    # It should be impossible for this function to be reentrant - the only places it
    # can be called from are open() below and from the setTimeout above (which is disabled
    # when reconnect is called). I'll just check it anyway though, because its sort of important.
    throw new Error 'Reconnect() called from invalid state' if session

    setState BCSocket.CONNECTING
    self['onconnecting']?()

    clearTimeout reconnectTimer

    session = new goog.net.BrowserChannel options['appVersion']
    session.setHandler handler
    lastErrorCode = null

    session.setFailFast yes if options['failFast']

    # Only needed for debugging..
    #session.setChannelDebug(new goog.net.ChannelDebug())

    session.connect "#{url}/test", "#{url}/bind", null,
      lastSession?.getSessionId(), lastSession?.getLastArrayId()

  # This isn't in the normal websocket interface. It reopens a previously closed websocket
  # connection by reconnecting.
  @['open'] = ->
    # If the session is already open, you should call close() first.
    throw new Error 'Already open' unless self.readyState is self.CLOSED
    reconnect()

  # This closes the connection and stops it from reconnecting.
  @['close'] = ->
    clearTimeout reconnectTimer

    # I'm abusing lastErrorCode here so in the channelClosed handler I can make sure we don't
    # try to reconnect.
    lastErrorCode = goog.net.BrowserChannel.Error.OK

    return if self.readyState is BCSocket.CLOSED

    setState BCSocket.CLOSING

    # In theory, we don't transition to the CLOSED state until the server has received the disconnect
    # message. But in practice, disconnect() results in channelClosed() being called immediately.
    # The server is still notified, but only really as an afterthought.
    session.disconnect()

  # I really want @send to take a callback which is called when the message is either confirmed
  # received or failed. However, closure provides no callback when messages are sent.
  #
  # Note that you *can* send messages while the channel is connecting. Thats fine - any messages sent then should be sent with the
  # initial payload.
  @['sendMap'] = (map) ->
    # This is the raw way to send messages. This will die if the session isn't connected.
    throw new Error 'Cannot send to a closed connection' if self.readyState in [BCSocket.CLOSING, BCSocket.CLOSED]
    session.sendMap map

  # This sends a map of {JSON:"..."}. It is interpretted as a native message by the server.
  @['send'] = (message) ->
    @['sendMap'] 'JSON': goog.json.serialize message
  
  # Websocket connections are automatically opened.
  reconnect()

  this

BCSocket.prototype['CONNECTING'] = BCSocket['CONNECTING'] = BCSocket.CONNECTING = 0
BCSocket.prototype['OPEN'] = BCSocket['OPEN'] = BCSocket.OPEN = 1
BCSocket.prototype['CLOSING'] = BCSocket['CLOSING'] = BCSocket.CLOSING = 2
BCSocket.prototype['CLOSED'] = BCSocket['CLOSED'] = BCSocket.CLOSED = 3

(exports ? window)['BCSocket'] = BCSocket
