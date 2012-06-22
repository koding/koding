# # A BrowserChannel server.
#
# - Its still pretty young, so there's probably bugs lurking around and the API
#   will still change quickly.
# - Its missing integration tests
#
# It works in all the browsers I've tried.
#
# I've written this using the literate programming style to try it out. So, thats why
# there's a million comments everywhere.
#
# The server is implemented as connect middleware. Its intended to be used like this:
#
# ```
# server = connect(
#   browserChannel (client) -> client.send 'hi'
# )
# ```

# ## Dependancies, helper methods and constant data

# `parse` helps us decode URLs in requests
{parse} = require 'url'
# `querystring` will help decode the URL-encoded forward channel data
querystring = require 'querystring'
# `fs` is used to read & serve the client library
fs = require 'fs'

# Client sessions are `EventEmitters`
{EventEmitter} = require 'events'
# Client session Ids are generated using `node-hat`
hat = require('hat').rack(40, 36)

# `randomInt(n)` generates and returns a random int smaller than n (0 <= k < n)
randomInt = (n) -> Math.floor(Math.random() * n)

# `randomArrayElement(array)` Selects and returns a random element from *array*
randomArrayElement = (array) -> array[randomInt(array.length)]

# For testing we'll override `setInterval`, etc with special testing stub versions (so
# we don't have to actually wait for actual *time*. To do that, we need local variable
# versions (I don't want to edit the global versions). ... and they'll just point to the
# normal versions anyway.
{setInterval, clearInterval, setTimeout, clearTimeout, Date} = global

# The module is configurable
defaultOptions =
  # An optional array of host prefixes. Each browserchannel client will randomly pick
  # from the list of host prefixes when it connects. This reduces the impact of per-host
  # connection limits.
  #
  # All host prefixes should point to the same server. Ie, if your server's hostname
  # is *example.com* and your hostPrefixes contains ['a', 'b', 'c'],
  # a.example.com, b.example.com and c.example.com should all point to the same host
  # as example.com.
  hostPrefixes: null

  # You can specify the base URL which browserchannel connects to. Change this if you want
  # to scope browserchannel in part of your app, or if you want /channel to mean something
  # else, or whatever.
  base: '/channel'

  # We'll send keepalives every so often to make sure the http connection isn't closed by
  # eagar clients. The standard timeout is 30 seconds, so we'll default to sending them
  # every 20 seconds or so.
  keepAliveInterval: 20 * 1000

  # After awhile (30 seconds or so) of not having a backchannel connected, we'll evict the
  # session completely. This will happen whenever a user closes their browser.
  sessionTimeoutInterval: 30 * 1000

  # By default, browsers don't allow access via javascript to foreign sites. You can use the
  # cors: option to set the Access-Control-Allow-Origin header in responses, which tells browsers
  # whether or not to allow cross domain requests to be sent.
  #
  # See https://developer.mozilla.org/en/http_access_control for more information.
  #
  # Setting cors:'*' will enable javascript from any domain to access your application. BE CAREFUL!
  # If your application uses cookies to manage user sessions, javascript on a foreign site could
  # make requests as if it were acting on behalf of one of your users.
  cors: null

  # A user can override all the headers if they want by setting the headers option to an object.
  headers: null

# All server responses set some standard HTTP headers.
# To be honest, I don't know how many of these are necessary. I just copied
# them from google.
#
# The nocache headers in particular seem unnecessary since each client
# request includes a randomized `zx=junk` query parameter.
standardHeaders =
  'Content-Type': 'text/plain'
  'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate'
  'Pragma': 'no-cache'
  'Expires': 'Fri, 01 Jan 1990 00:00:00 GMT'
  'X-Content-Type-Options': 'nosniff'

  # Gmail also sends this, though I'm not really sure what it does...
#  'X-Xss-Protection': '1; mode=block'

# The one exception to that is requests destined for iframes. They need to
# have content-type: text/html set for IE to process the juicy JS inside.
ieHeaders = {}
ieHeaders[k] = v for k, v of standardHeaders
ieHeaders['Content-Type'] = 'text/html'

# Google's browserchannel server adds some junk after the first message data is sent. I
# assume this stops some whole-page buffering in IE. I assume the data used is noise so it
# doesn't compress.
#
# I don't really know why google does this. I'm assuming there's a good reason to it though.
ieJunk = "7cca69475363026330a0d99468e88d23ce95e222591126443015f5f462d9a177186c8701fb45a6ffe
e0daf1a178fc0f58cd309308fba7e6f011ac38c9cdd4580760f1d4560a84d5ca0355ecbbed2ab715a3350fe0c47
9050640bd0e77acec90c58c4d3dd0f5cf8d4510e68c8b12e087bd88cad349aafd2ab16b07b0b1b8276091217a44
a9fe92fedacffff48092ee693af\n"

# If the user is using IE, instead of using XHR backchannel loaded using
# a forever iframe. When data is sent, it is wrapped in <script></script> tags
# which call functions in the browserchannel library.
#
# This method wraps the normal `.writeHead()`, `.write()` and `.end()` methods by
# special versions which produce output based on the request's type.
#
# This **is not used** for:
#
# - The first channel test
# - The first *bind* connection a client makes. The server sends arrays there, but the
#   connection is a POST and it returns immediately. So that request happens using XHR/Trident
#   like regular forward channel requests.
messagingMethods = (options, query, res) ->
  type = query.TYPE
  if type == 'html'
    junkSent = false

    methods =
      writeHead: ->
        res.writeHead 200, 'OK', ieHeaders
        res.write '<html><body>'

        domain = query.DOMAIN
        # If the iframe is making the request using a secondary domain, I think we need
        # to set the `domain` to the original domain so that we can call the response methods.
        if domain and domain != ''
          # Make sure the domain doesn't contain anything by naughty by `JSON.stringify()`-ing
          # it before passing it to the client. There are XSS vulnerabilities otherwise.
          res.write "<script>try{document.domain=#{JSON.stringify domain};}catch(e){}</script>\n"
    
      write: (data) ->
        # The data is passed to `m()`, which is bound to *onTridentRpcMessage_* in the client.
        res.write "<script>try {parent.m(#{JSON.stringify data})} catch(e) {}</script>\n"
        unless junkSent
          res.write ieJunk
          junkSent = true

      end: ->
        # Once the data has been received, the client needs to call `d()`, which is bound to
        # *onTridentDone_* with success=*true*.
        # The weird spacing of this is copied from browserchannel. Its really not necessary.
        res.end "<script>try  {parent.d(); }catch (e){}</script>\n"

      # This is a helper method for signalling an error in the request back to the client.
      writeError: (statusCode, message) ->
        # The HTML (iframe) handler has no way to discover that the embedded script tag
        # didn't complete successfully. To signal errors, we return **200 OK** and call an
        # exposed rpcClose() method on the page.
        methods.writeHead()
        res.end "<script>try {parent.rpcClose(#{JSON.stringify message})} catch(e){}</script>\n"

    # For some reason, sending data during the second test (111112) works slightly differently for
    # XHR, but its identical for html encoding. We'll use a writeRaw() method in that case, which
    # is copied in the case of html.
    methods.writeRaw = methods.write

    methods

  else
    # For normal XHR requests, we send data normally.
    writeHead: -> res.writeHead 200, 'OK', options.headers
    write: (data) -> res.write "#{data.length}\n#{data}"
    writeRaw: (data) -> res.write data
    end: -> res.end()
    writeError: (statusCode, message) ->
      res.writeHead statusCode, options.headers
      res.end message

# For telling the client its done bad.
#
# It turns out google's server isn't particularly fussy about signalling errors using the proper
# html RPC stuff, so this is useful for html connections too.
sendError = (res, statusCode, message) ->
  res.writeHead statusCode, message
  res.end "<html><body><h1>#{message}</h1></body></html>"
  return

# ## Parsing client maps from the forward channel
#
# The client sends data in a series of url-encoded maps. The data is encoded like this:
# 
# ```
# count=2&ofs=0&req0_x=3&req0_y=10&req1_abc=def
# ```
#
# First, we need to buffer up the request response and query string decode it.
bufferPostData = (req, callback) ->
  data = []
  req.on 'data', (chunk) ->
    data.push chunk.toString 'utf8'
  req.on 'end', ->
    data = data.join ''
    callback data

# Next, we'll need to decode the incoming client data into an array of objects.
#
# The data could be in two different forms:
# 
# - Classical browserchannel format, which is a bunch of string->string url-encoded maps
# - A JSON object
#
# We can tell what format the data is in by inspecting the content-type header
#
# ## URL Encoded data
#
# Essentially, url encoded the data looks like this:
#
# ```
# { count: '2',
#   ofs: '0',
#   req0_x: '3',
#   req0_y: '10',
#   req1_abc: 'def'
# }
# ```
#
# ... and we will return an object in the form of `[{x:'3', y:'10'}, {abc: 'def'}, ...]`
#
# ## JSON Encoded data
#
# JSON encoded the data looks like:
#
# ```
# { ofs: 0
# , data: [null, {...}, 1000.4, 'hi', ...]
# }
# ```
#
# or `null` if there's no data.
#
# This function returns null if there's no data or {ofs, json:[...]} or {ofs, maps:[...]}
transformData = (req, data) ->
  if req.headers['content-type'] == 'application/json'
    # We'll restructure it slightly to mark the data as JSON rather than maps.
    {ofs, data} = data
    {ofs, json:data}
  else
    count = parseInt data.count
    return null if count is 0

    # ofs will be missing if count is zero
    ofs = parseInt data.ofs
    throw new Error 'invalid map data' if isNaN count or isNaN ofs
    throw new Error 'Invalid maps' unless count == 0 or (count > 0 and data.ofs?)

    maps = new Array count

    # Scan through all the keys in the data. Every key of the form:
    # `req123_xxx` will be used to populate its map.
    regex = /^req(\d+)_(.+)$/
    for key, val of data
      match = regex.exec key
      if match
        id = match[1]
        mapKey = match[2]
        map = (maps[id] ||= {})
        # The client uses `mapX_type=_badmap` to signify an error encoding a map.
        continue if id == 'type' and mapKey == '_badmap'
        map[mapKey] = val

    {ofs, maps}

# Decode data string body and get an object back
# Either a query string format or JSON depending on content type
decodeData = (req, data) ->
  if req.headers['content-type'] == 'application/json'
    JSON.parse data
  else
    # Maps. Ugh.
    querystring.parse data


# This is a helper method to order the handling of messages / requests / whatever.
#
# Use it like this:
# inOrder = order 0
#
# inOrder 1, -> console.log 'second'
# inOrder 0, -> console.log 'first'
#
# Start is the ID of the first element we expect to receive. If we get data for earlier
# elements, we'll play them anyway if playOld is truthy.
order = (start, playOld) ->
  # Base is the ID of the (missing) element at the start of the queue
  base = start
  # The queue will start with about 10 elements. Elements of the queue are undefined
  # if we don't have data for that queue element.
  queue = new Array 10

  (seq, callback) ->
    # Its important that all the cells of the array are truthy if we have data. We'll use an
    # empty function instead of null.
    callback or= ->

    # Ignore old messages, or play them back immediately if playOld=true
    if seq < base
      callback() if playOld
    else
      queue[seq - base] = callback

      while queue[0]
        callback = queue.shift()
        base++
        callback()

# We need access to the client's sourcecode. I'm going to get it using a synchronous file call
# (it'll be fast anyway, and only happen once).
#
# I'm also going to set an etag on the client data so the browser client will be cached. I'm kind of
# uncomfortable about adding complexity here because its not like this code hasn't been written
# before, but.. I think a lot of people will use this API.
#
# I should probably look into hosting the client code as a javascript module using that client-side
# npm thing.
clientFile = "#{__dirname}/../dist/bcsocket.js"
clientStats = fs.statSync clientFile
try
  clientCode = fs.readFileSync clientFile, 'utf8'
catch e
  console.error 'Could not load the client javascript. Run `cake client` to generate it.'
  throw e

# This is mostly to help development, but if the client is recompiled, I'll pull in a new version.
# This isn't tested by the unit tests - but its not a big deal.
#
# The `readFileSync` call here will stop the whole server while the client is reloaded.
# This will only happen during development so its not a big deal.
if process.platform is "win32"
  # Windows doesn't support watchFile. See:
  # https://github.com/josephg/node-browserchannel/pull/6
  fs.watch clientFile, persistent: false, (event, filename) ->
    if event is "change"
      console.log "Reloading client JS"
      clientCode = fs.readFileSync clientFile, 'utf8'
      clientStats = curr
else
  fs.watchFile clientFile, persistent: false, (curr, prev) ->
    if curr.mtime.getTime() isnt prev.mtime.getTime()
      console.log "Reloading client JS"
      clientCode = fs.readFileSync clientFile, 'utf8'
      clientStats = curr

# ---
#
# # The server middleware
#
# The server module returns a function, which you can call with your configuration
# options. It returns your configured connect middleware, which is actually another function.
module.exports = browserChannel = (options, onConnect) ->
  if typeof onConnect == 'undefined'
    onConnect = options
    options = {}

  options ||= {}
  options[option] ?= value for option, value of defaultOptions

  options.headers = {} unless options.headers
  options.headers[h] ||= v for h, v of standardHeaders
  options.headers['Access-Control-Allow-Origin'] = options.cors if options.cors

  # Strip off a trailing slash in base.
  base = options.base
  base = base[... base.length - 1] if base.match /\/$/
  
  # Add a leading slash back on base
  base = "/#{base}" unless base.match /^\//

  # map from sessionId -> session
  sessions = {}

  # Host prefixes provide a way to skirt around connection limits. They're only
  # really important for old browsers.
  getHostPrefix = ->
    if options.hostPrefixes
      randomArrayElement options.hostPrefixes
    else
      null

  # # Create a new client session.
  #
  # This method will start a new client session.
  #
  # Session ids are generated by [node-hat]. They are guaranteed to be unique.
  # [node-hat]: https://github.com/substack/node-hat
  #
  # This method is synchronous, because a database will never be involved in browserchannel
  # session management. Browserchannel sessions only last as long as the user's browser
  # is open. If there's any connection turbulence, the client will reconnect and get
  # a new session id.
  #
  # Sometimes a client will specify an old session ID and old array ID. In this case, the client
  # is reconnecting and we should evict the named session (if it exists).
  createSession = (address, query, headers) ->
    {RID:initialRid, CVER:appVersion, OSID:oldSessionId, OAID:oldArrayId} = query

    if oldSessionId? and (oldSession = sessions[oldSessionId])
      oldSession._acknowledgeArrays oldArrayId
      oldSession.close 'Reconnected'

    # Create a new session. Sessions extend node's [EventEmitter][] so they have access to
    # goodies like `session.on(event, handler)`, `session.emit('paarty')`, etc.
    # [EventEmitter]: http://nodejs.org/docs/v0.4.12/api/events.html
    session = new EventEmitter

    # The session's unique ID for this connection
    session.id = hat()

    # The client stores its IP address and headers from when it first opened the session. The
    # handler can use this information for authentication or something.
    session.address = address
    session.headers = headers

    # The session is a little state machine. It has the following states:
    #
    # - **init**: The session has been created and its sessionId hasn't been sent yet.
    #   The session moves to the **ok** state when the first data chunk is sent to the
    #   client.
    #
    # - **ok**: The session is sitting pretty and ready to send and receive data.
    #   The session will spend most of its time in this state.
    #
    # - **closed**: The session has been removed from the session list. It can no longer
    #   be used for any reason.
    #
    #   It is invalid to send arrays to a session while it is closed. Unless you're
    #   Bruce Willis...
    session.state = 'init'

    # The state is modified through this method. It emits events when the state changes.
    # (yay)
    changeState = (newState) ->
      oldState = session.state
      session.state = newState
      session.emit 'state changed', session.state, oldState

    # The server sends messages to the client via a hanging GET request. Of course,
    # the client has to be the one to open that request.
    #
    # This is a handle to null, or {res, methods, chunk}
    #
    # - **res** is the http response object
    # - **methods** is a map of send(), etc methods for communicating properly with the backchannel -
    #   this will be different if the request comes from IE or not.
    # - **chunk** specifies whether or not we're going to keep the connection open across multiple
    #   messages. If there's a buffering proxy in the way of the connection, we can't respond a bit at
    #   a time, so we close the backchannel after each data chunk. The client decides this during
    #   testing and passes a CI= parameter to the server when the backchannel connection is established.
    # - **bytesSent** specifies how many bytes of data have been sent through the backchannel. We periodically
    #   close the backchannel and let the client reopen it, so things like the chrome web inspector stay
    #   usable.
    backChannel = null

    # The server sends data to the client by sending *arrays*. It seems a bit silly that
    # client->server messages are maps and server->client messages are arrays, but there it is.
    #
    # Each entry in this array is of the form [id, data].
    outgoingArrays = []

    # `lastArrayId` is the array ID of the last queued array
    lastArrayId = -1

    # Every request from the client has an *AID* parameter which tells the server the ID
    # of the last request the client has received. We won't remove arrays from the outgoingArrays
    # list until the client has confirmed its received them.
    #
    # In `lastSentArrayId` we store the ID of the last array which we actually sent.
    lastSentArrayId = -1

    # I would like this method to be private or something, but it needs to be accessed from
    # the HTTP request code below. The _ at the start will hopefully make people think twice
    # before using it.
    session._setBackChannel = (res, query) ->
      clearBackChannel()

      backChannel =
        res: res
        methods: messagingMethods options, query, res
        chunk: query.CI == '0'
        bytesSent: 0
        listener: ->
          backChannel.listener = null
          clearBackChannel res

      # When the TCP connection underlying the backchannel request is closed, we'll stop using the
      # backchannel and start the session timeout clock. The listener is kept so the event handler 
      # removed once the backchannel is closed.
      res.connection.once 'close', backChannel.listener

      # We'll start the heartbeat interval and clear out the session timeout.
      # The session timeout will be started again if the backchannel connection closes for
      # any reason.
      refreshHeartbeat()
      clearTimeout sessionTimeout

      # When a new backchannel is created, its possible that the old backchannel is dead.
      # In this case, its possible that previously sent arrays haven't been received.
      # By resetting lastSentArrayId, we're effectively rolling back the status of sent arrays
      # to only those arrays which have been acknowledged.
      lastSentArrayId = outgoingArrays[0].id - 1 if outgoingArrays.length > 0

      # Send any arrays we've buffered now that we have a backchannel
      @flush()

    # If we haven't sent anything for 15 seconds, we'll send a little `['noop']` to the
    # client so it knows we haven't forgotten it. (And to make sure the backchannel
    # connection doesn't time out.)
    heartbeat = null

    # This method removes the back channel and any state associated with it. It'll get called
    # when the backchannel closes naturally, is replaced or when the connection closes.
    clearBackChannel = (res) ->
      # clearBackChannel doesn't do anything if we call it repeatedly.
      return unless backChannel
      # Its important that we only delete the backchannel if the closed connection is actually
      # the backchannel we're currently using.
      return if res? and res != backChannel.res

      if backChannel.listener
        # The backchannel listener has been attached to the 'close' event of the underlying TCP
        # stream. We don't care about that anymore
        backChannel.res.connection.removeListener 'close', backChannel.listener
        backChannel.listener = null

      # Conveniently, clearTimeout has no effect if the argument is null.
      clearTimeout heartbeat

      backChannel.methods.end()
      backChannel = null

      # Whenever we don't have a backchannel, we run the session timeout timer.
      refreshSessionTimeout()

    # This method sets / resets the heartbeat timeout to the full 15 seconds.
    refreshHeartbeat = ->
      clearTimeout heartbeat

      heartbeat = setInterval (-> session.send ['noop']), options.keepAliveInterval

    # The session will close if there's been no backchannel for awhile.
    sessionTimeout = null

    refreshSessionTimeout = ->
      clearTimeout sessionTimeout
      sessionTimeout = setTimeout (-> session.close 'Timed out'), options.sessionTimeoutInterval

    # Since the session doesn't start with a backchannel, we'll kick off the timeout timer as soon as its
    # created.
    refreshSessionTimeout()

    # The arrays get removed once they've been acknowledged
    session._acknowledgeArrays = (id) ->
      id = parseInt id if typeof id is 'string'

      while outgoingArrays.length > 0 and outgoingArrays[0].id <= id
        {confirmcallback} = outgoingArrays.shift()
        # I've got no idea what to do if we get an exception thrown here. The session will end up
        # in an inconsistant state...
        confirmcallback?()

      return

    # Queue an array to be sent. The optional callbacks notifies a caller when the array has been
    # sent, and then received by the client.
    #
    # queueArray returns the ID of the queued data chunk.
    queueArray = (data, sendcallback, confirmcallback) ->
      throw new Error "Cannot queue array when the session is already closed" if session.state == 'closed'

      id = ++lastArrayId
      outgoingArrays.push {id, data, sendcallback, confirmcallback}

      lastArrayId

    # The session has just been created. The first thing it needs to tell the client
    # is its session id and host prefix and stuff.
    #
    # It would be pretty easy to add a callback here setting the client status to 'ok' or
    # something, but its not really necessary. The client has already connected once the first
    # POST /bind has been received.
    queueArray ['c', session.id, getHostPrefix(), 8]
        
    # Send the array data through the backchannel. This takes an optional callback which
    # will be called with no arguments when the client acknowledges the array, or called with an
    # error object if the client disconnects before the array is sent.
    #
    # queueArray can also take a callback argument which is called when the session sends the message
    # in the first place. I'm not sure if I should expose this through send - I can't tell if its
    # useful beyond the server code.
    session.send = (arr, callback) ->
      id = queueArray arr, null, callback
      @flush()
      id

    # ### Maps
    # 
    # The client sends maps to the server using POST requests. Its possible for the requests
    # to come in out of order, so sometimes we need to buffer up incoming maps and reorder them
    # before emitting them to the user.
    #
    # Each map has an ID (which starts at 0 when the session is first created). 

    # We'll emit received data to the user immediately if they're in order, but if they're out of order
    # we'll use the little order helper above to order them. The order helper is instructed to not
    # emit any old messages twice.
    #
    # There's a potential DOS attack here whereby a client could just spam the server with
    # out-of-order maps until it runs out of memory. We should dump a session if there are
    # too many entries in this dictionary.
    mapBuffer = order 0, false

    # This method is called whenever we get maps from the client. Offset is the ID of the first
    # map. The data could either be maps or JSON data. If its maps, data contains {maps} and if its
    # JSON data, maps contains {JSON}.
    #
    # Browserchannel has 2 different mechanisms for consistantly ordering messages in the forward channel:
    #
    # - Each forward channel request contains a request ID (RID=X), which start at a random value
    #   (set with the first session create packet). These increment by 1 with each request.
    #
    #   If a request fails, it might be retried with the same RID as the previous message, and with extra
    #   maps tacked on the end. We need to handle the maps in this case.
    #
    # - Each map has an ID, counting from 0. ofs= in the POST data tells the server the ID of the first
    #   map in a request.
    #
    # As far as I can tell, the RID stuff can mostly be ignored. The one place it is important is in
    # handling disconnect messages. The session should only be disconnected by a disconnect message when
    # the preceeding messages have been received.

    # All requests are handled in order too, though if not for disconnecting I don't think it would matter.
    # Because of the funky retry-has-extra-maps logic, we'll allow processing requests twice.
    ridBuffer = order initialRid, true

    session._receivedData = (rid, data) ->
      ridBuffer rid, ->
        return if data is null
        throw new Error 'Invalid data' unless data.maps? or data.json?

        ridBuffer rid
        id = data.ofs

        # First, classic browserchannel maps.
        if data.maps
          # If an exception is thrown during this loop, I'm not really sure what the behaviour should be.
          for map in data.maps
            # The funky do expression here is used to pass the map into the closure.
            # Another way to do it is to index into the data.maps array inside the function, but then I'd
            # need to pass the index to the closure anyway.
            mapBuffer id++, do (map) -> ->
              return if session.state is 'closed'

              session.emit 'map', map

              # If you specify the key as JSON, the server will try to decode JSON data from the map and emit
              # 'message'. This is a much nicer way to message the server.
              if map.JSON?
                try
                  message = JSON.parse map.JSON
                  session.emit 'message', message
        else
          # We have data.json. We'll just emit it directly.
          for message in data.json
            mapBuffer id++, do (map) -> ->
              return if session.state is 'closed'
              session.emit 'message', message

    session._disconnectAt = (rid) ->
      ridBuffer rid, -> session.close 'Disconnected'

    # When we receive forwardchannel data, we reply with a special little 3-variable array to tell the
    # client if it should reopen the backchannel.
    #
    # This method returns what the forward channel should reply with.
    session._backChannelStatus = ->
      # Find the arrays have been sent over the wire but haven't been acknowledged yet
      numUnsentArrays = lastArrayId - lastSentArrayId
      unacknowledgedArrays = outgoingArrays[... outgoingArrays.length - numUnsentArrays]
      outstandingBytes = if unacknowledgedArrays.length == 0
        0
      else
        # We don't care about the length of the array IDs or callback functions.
        # I'm actually not sure what data the client expects here - the value is just used in a rough
        # heuristic to determine if the backchannel should be reopened.
        data = (a.data for a in unacknowledgedArrays)
        JSON.stringify(data).length

      [
        (if backChannel then 1 else 0)
        lastSentArrayId
        outstandingBytes
      ]

    # ## Encoding server arrays for the back channel
    #
    # The server sends data to the client in **chunks**. Each chunk is a *JSON* array prefixed
    # by its length in bytes.
    #
    # The array looks like this:
    #
    # ```
    # [
    #   [100, ['message', 'one']],
    #   [101, ['message', 'two']],
    #   [102, ['message', 'three']]
    # ]
    # ```
    #
    # Each individial message is prefixed by its *array id*, which is a counter starting at 0
    # when the session is first created and incremented with each array.

    # This will actually send the arrays to the backchannel on the next tick if the backchannel
    # is alive.
    session.flush = ->
      process.nextTick ->
        if backChannel
          numUnsentArrays = lastArrayId - lastSentArrayId
          if numUnsentArrays > 0
            arrays = outgoingArrays[outgoingArrays.length - numUnsentArrays ...]

            # I've abused outgoingArrays to also contain some callbacks. We only send [id, data] to
            # the client.
            data = ([id, data] for {id, data} in arrays)
            bytes = JSON.stringify(data) + "\n"

            # Stand back, pro hax! Ideally there is a general solution for escaping these characters
            # when converting to JSON.
            bytes = bytes.replace(/\u2028/g, "\\u2028")
            bytes = bytes.replace(/\u2029/g, "\\u2029")

            # **Away!**
            backChannel.methods.write bytes
            backChannel.bytesSent += bytes.length

            lastSentArrayId = lastArrayId

            # Fire any send callbacks on the messages. These callbacks should only be called once.
            # Again, not sure what to do if there are exceptions here.
            for a in arrays
              if a.sendcallback?
                a.sendcallback?()
                delete a.sendcallback

            if !backChannel.chunk or backChannel.bytesSent > 10 * 1024
              clearBackChannel()

          # The first backchannel is the client's initial connection. Once we've sent the first
          # data chunk to the client, we've officially opened the connection.
          changeState 'ok' if session.state == 'init'
  
    # The client's reported application version, or null. This is sent when the
    # connection is first requested, so you can use it to make your application die / stay
    # compatible with people who don't close their browsers.
    session.appVersion = appVersion or null

    # Signal to a client that it should stop trying to connect. This has no other effect
    # on the server session.
    #
    # `stop` takes a callback which will be called once the message has been *sent* by the server.
    # Typically, you should call it like this:
    #
    # ```
    # session.stop ->
    #   session.close()
    # ```
    #
    # I considered making this automatically close the connection after you've called it, or after
    # you've sent the stop message or something, but if I did that it wouldn't be obvious that you
    # can still receive messages after stop() has been called. (Because you can!). That would never
    # come up when you're testing locally, but it *would* come up in production. This is more obvious.
    session.stop = (callback) ->
      return if @state is 'closed'
      queueArray ['stop'], callback, null
      @flush()

    # This closes a session and makes the server forget about it.
    #
    # The client might try and reconnect if you only call `close()`. It'll get a new session if it does so.
    #
    # close takes an optional message argument, which is passed to the send event handlers.
    session.close = (message) ->
      # You can't double-close.
      return if @state == 'closed'

      changeState 'closed'
      @emit 'close', message

      clearBackChannel()
      clearTimeout sessionTimeout

      for {confirmcallback} in outgoingArrays
        confirmcallback?(new Error message || 'closed')
      
      delete sessions[@id]
      #console.log "closed #{@id}"

    sessions[session.id] = session

    session

  # This is the returned middleware. Connect middleware is a function which
  # takes in an http request, an http response and a next method.
  #
  # The middleware can do one of two things:
  #
  # - Handle the request, sending data back to the server via the response
  # - Call `next()`, which allows the next middleware in the stack a chance to
  #   handle the request.
  middleware = (req, res, next) ->
    {query, pathname} = parse req.url, true
    #console.warn req.method, req.url
    
    # If base is /foo, we don't match /foobar. (Currently no unit tests for this)
    return next() if pathname.substring(0, base.length + 1) != "#{base}/"

    {writeHead, write, writeRaw, end, writeError} = messagingMethods options, query, res

    # # Serving the client
    #
    # The browserchannel server hosts a usable web client library at /CHANNEL/bcsocket.js.
    # This library wraps the google closure library client implementation.
    #
    # If I have time, I would like to write my own version of the client to add a few features
    # (websockets, message acknowledgement callbacks) and do some manual optimisations for speed.
    # However, the current version works ok.
    if pathname is "#{base}/bcsocket.js"
      etag = "\"#{clientStats.size}-#{clientStats.mtime.getTime()}\""
      res.writeHead 200, 'OK',
        'Content-Type': 'application/javascript',
        'ETag': etag,
        'Content-Length': clientCode.length
      # This code is manually tested because it looks like its impossible to send HEAD requests
      # using nodejs's HTTP library at time of writing (0.4.12). (Yeah, I know, rite?)
      if req.method is 'HEAD'
        res.end()
      else
        res.end clientCode

    # # Connection testing
    #
    # Before the browserchannel client connects, it tests the connection to make
    # sure its working, and to look for buffering proxies.
    #
    # The server-side code for connection testing is completely stateless.
    else if pathname is "#{base}/test"
      # This server only supports browserchannel protocol version **8**.
      # I have no idea if 400 is the right error here.
      return sendError res, 400, 'Version 8 required' unless query.VER is '8'

      #### Phase 1: Server info
      # The client is requests host prefixes. The server responds with an array of
      # ['hostprefix' or null, 'blockedprefix' or null].
      #
      # > Actually, I think you might be able to return [] if neither hostPrefix nor blockedPrefix
      # > is defined. (Thats what google wave seems to do)
      #
      # - **hostprefix** is subdomain prepended onto the hostname of each request.
      # This gets around browser connection limits. Using this requires a bank of
      # configured DNS entries and SSL certificates if you're using HTTPS.
      #
      # - **blockedprefix** provides network admins a way to blacklist browserchannel
      # requests. It is not supported by node-browserchannel.
      if query.MODE == 'init' and req.method == 'GET'
        hostPrefix = getHostPrefix()
        blockedPrefix = null # Blocked prefixes aren't supported.

        # We add an extra special header to tell the client that this server likes
        # json-encoded forward channel data over form urlencoded channel data.
        #
        # It might be easier to put these headers in the response body or increment the
        # version, but that might conflict with future browserchannel versions.
        headers = {}
        headers[k] = v for k, v of options.headers
        headers['X-Accept'] = 'application/json; application/x-www-form-urlencoded'

        # This is a straight-up normal HTTP request like the forward channel requests.
        # We don't use the funny iframe write methods.
        res.writeHead 200, 'OK', headers
        res.end(JSON.stringify [hostPrefix, blockedPrefix])

      else
        #### Phase 2: Buffering proxy detection
        # The client is trying to determine if their connection is buffered or unbuffered.
        # We reply with '11111', then 2 seconds later '2'.
        #
        # The client should get the data in 2 chunks - but they won't if there's a misbehaving
        # corporate proxy in the way or something.
        writeHead()
        writeRaw '11111'
        setTimeout (-> writeRaw '2'; end()), 2000

    # # BrowserChannel connection
    #
    # Once a client has finished testing its connection, it connects.
    #
    # BrowserChannel communicates through two connections:
    #
    # - The **forward channel** is used for the client to send data to the server.
    #   It uses a **POST** request for each message.
    # - The **back channel** is used to get data back from the server. This uses a
    #   hanging **GET** request. If chunking is disallowed (ie, if the proxy buffers)
    #   then the back channel is closed after each server message.
    else if pathname == "#{base}/bind"
      # I'm copying the behaviour of unknown SIDs below. I don't know how the client
      # is supposed to detect this error, but, eh. The other choice is to `return writeError ...`
      return sendError res, 400, 'Version 8 required' unless query.VER is '8'

      # All browserchannel connections have an associated client object. A client
      # is created immediately if the connection is new.
      if query.SID
        session = sessions[query.SID]
        # This is a special error code for the client. It tells the client to abandon its
        # connection request and reconnect.
        #
        # For some reason, google replies with the same response on HTTP and HTML requests here.
        # I'll follow suit, though its a little weird. Maybe I should do the same with all client
        # errors?
        return sendError res, 400, 'Unknown SID' unless session

      session._acknowledgeArrays query.AID if query.AID? and session

      # ### Forward Channel
      if req.method == 'POST'
        if session == undefined
          
          # The session is new! Make them a new session object and let the
          # application know.
          session = createSession req.connection.remoteAddress, query, req.headers
          onConnect? session

        dataError = (e) ->
            console.warn 'Error parsing forward channel', e.stack
            return sendError res, 400, 'Bad data'

        processData = (data) ->
          try
            data = transformData req, data
            session._receivedData query.RID, data
          catch e
            return dataError e
          if session.state is 'init'
            # The initial forward channel request is also used as a backchannel for the server's
            # initial data (session id, etc). This connection is a little bit special - it is always
            # encoded using length-prefixed json encoding and it is closed as soon as the first chunk is
            # sent.
            res.writeHead 200, 'OK', options.headers
            session._setBackChannel res, CI:1, TYPE:'xmlhttp', RID:'rpc'
            session.flush()
          else if session.state is 'closed'
            # If the onConnect handler called close() immediately, session.state can be already closed at this point.
            # I'll assume there was an authentication problem and treat this as a forbidden connection attempt.
            sendError res, 403, 'Forbidden'
          else
            # On normal forward channels, we reply to the request by telling the session
            # if our backchannel is still live and telling it how many unconfirmed
            # arrays we have.
            response = JSON.stringify session._backChannelStatus()
            res.writeHead 200, 'OK', options.headers
            res.end "#{response.length}\n#{response}"

        if req.body
          processData req.body
        else
          bufferPostData req, (data) ->
            try
              data = decodeData req, data
            catch e
              return dataError e
            processData data

      else if req.method is 'GET'
        # ### Back channel
        #
        # GET messages are usually backchannel requests (server->client). Backchannel messages are handled
        # by the session object.
        if query.TYPE in ['xmlhttp', 'html']
          return sendError res, 400, 'Invalid SID' if typeof query.SID != 'string' && query.SID.length < 5
          return sendError res, 400, 'Expected RPC' unless query.RID is 'rpc'
          writeHead()
          session._setBackChannel res, query
        # The client can manually disconnect by making a GET request with TYPE='terminate'
        else if query.TYPE is 'terminate'
          # We don't send any data in the response to the disconnect message.
          #
          # The client implements this using an img= appended to the page.
          session?._disconnectAt query.RID
          res.writeHead 200, 'OK', options.headers
          res.end()

      else
        res.writeHead 405, 'Method Not Allowed', options.headers
        res.end "Method not allowed"

    else
      # We'll 404 the user instead of letting another handler take care of it.
      # Users shouldn't be using the specified URL prefix for anything else.
      res.writeHead 404, 'Not Found', options.headers
      res.end "Not found"

  middleware.close = -> session.close() for id, session of sessions

  # This is an undocumented, untested treat - if you pass the HTTP server / connect server to
  # browserchannel through the options object, it can attach a close listener for you automatically.
  options.server?.on 'close', middleware.close

  middleware

# This will override the timer methods (`setInterval`, etc) with the testing stub versions,
# which are way faster.
browserChannel._setTimerMethods = (methods) ->
  {setInterval, clearInterval, setTimeout, clearTimeout, Date} = methods
