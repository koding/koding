# # Unit tests for BrowserChannel server
#
# This contains all the unit tests to make sure the server works like it should.
#
# This is designed to be run using nodeunit. To run the tests, install nodeunit:
#
#     npm install -g nodeunit
#
# then run the server tests with:
#
#     nodeunit test/server.coffee
#
# For now I'm not going to add in any SSL testing code. I should probably generate
# a self-signed key pair, start the server using https and make sure that I can
# still use it.
#
# I'm also missing integration tests.

{testCase} = require 'nodeunit'

http = require 'http'
assert = require 'assert'
querystring = require 'querystring'

timer = require 'timerstub'

browserChannel = require('..').server
browserChannel._setTimerMethods timer

{createServer} = require './helpers'

# Wait for the function to be called a given number of times, then call the callback.
#
# This useful little method has been stolen from ShareJS
expectCalls = (n, callback) ->
  return callback() if n == 0

  remaining = n
  ->
    remaining--
    if remaining == 0
      callback()
    else if remaining < 0
      throw new Error "expectCalls called more than #{n} times"

# This returns a function that calls test.done() after it has been called n times. Its
# useful when you want a bunch of mini tests inside one test case.
makePassPart = (test, n) ->
  expectCalls n, -> test.done()

# Most of these tests will make HTTP requests. A lot of the time, we don't care about the
# timing of the response, we just want to know what it was. This method will buffer the
# response data from an http response object and when the whole response has been received,
# send it on.
buffer = (res, callback) ->
  data = []
  res.on 'data', (chunk) ->
    #console.warn chunk.toString()
    data.push chunk.toString 'utf8'
  res.on 'end', -> callback data.join ''

# For some tests we expect certain data, delivered in chunks. Wait until we've
# received at least that much data and strcmp. The response will probably be used more,
# afterwards, so we'll make sure the listener is removed after we're done.
expect = (res, str, callback) ->
  data = ''
  res.on 'end', endlistener = ->
    # This should fail - if the data was as long as str, we would have compared them
    # already. Its important that we get an error message if the http connection ends
    # before the string has been received.
    console.warn 'Connection ended prematurely'
    assert.strictEqual data, str

  res.on 'data', listener = (chunk) ->
    # I'm using string += here because the code is easier that way.
    data += chunk.toString 'utf8'
    #console.warn JSON.stringify data
    #console.warn JSON.stringify str
    if data.length >= str.length
      assert.strictEqual data, str
      res.removeListener 'data', listener
      res.removeListener 'end', endlistener
      callback()

# A bunch of tests require that we wait for a network connection to get established
# before continuing.
#
# We'll do that using a setTimeout with plenty of time. I hate adding delays, but I
# can't see another way to do this.
#
# This should be plenty of time. I might even be able to reduce this. Note that this
# is a real delay, not a stubbed out timer like we give to the server.
soon = (f) -> setTimeout f, 10

readLengthPrefixedString = (res, callback) ->
  data = ''
  length = null
  res.on 'data', listener = (chunk) ->
    data += chunk.toString 'utf8'

    if length == null
      # The number of bytes is written in an int on the first line.
      lines = data.split '\n'
      # If lines length > 1, then we've read the first newline, which was after the length
      # field.
      if lines.length > 1
        length = parseInt lines.shift()

        # Now we'll rewrite the data variable to not include the length.
        data = lines.join '\n'

    if data.length == length
      res.removeListener 'data', listener
      callback data
    else if data.length > length
      console.warn data
      throw new Error "Read more bytes from stream than expected"

# The backchannel is implemented using a bunch of messages which look like this:
#
# ```
# 36
# [[0,["c","92208FBF76484C10",,8]
# ]
# ]
# ```
#
# (At least, thats what they look like using google's server. On mine, they're properly
# formatted JSON).
#
# Each message has a length string (in bytes) followed by a newline and some JSON data.
# They can optionally have extra chunks afterwards.
#
# This format is used for:
#
# - All XHR backchannel messages
# - The response to the initial connect (XHR or HTTP)
# - The server acknowledgement to forward channel messages
#
# This is not used when you're on IE, for normal backchannel requests. On IE, data is sent
# through javascript calls from an iframe.
readLengthPrefixedJSON = (res, callback) ->
  readLengthPrefixedString res, (data) ->
    callback JSON.parse(data)

# Copied from google's implementation. The contents of this aren't actually relevant,
# but I think its important that its pseudo-random so if the connection is compressed,
# it still recieves a bunch of bytes after the first message.
ieJunk = "7cca69475363026330a0d99468e88d23ce95e222591126443015f5f462d9a177186c8701fb45a6ffe
e0daf1a178fc0f58cd309308fba7e6f011ac38c9cdd4580760f1d4560a84d5ca0355ecbbed2ab715a3350fe0c47
9050640bd0e77acec90c58c4d3dd0f5cf8d4510e68c8b12e087bd88cad349aafd2ab16b07b0b1b8276091217a44
a9fe92fedacffff48092ee693af\n"

module.exports = testCase
  # #### setUp
  #
  # Before each test has run, we'll start a new server. The server will only live
  # for that test and then it'll be torn down again.
  #
  # This makes the tests run more slowly, but not slowly enough that I care.
  setUp: (callback) ->
    # This will make sure there's no pesky setTimeouts from previous tests kicking around.
    # I could instead do a timer.waitAll() in tearDown to let all the timers run & time out
    # the running sessions. It shouldn't be a big deal.
    timer.clearAll()

    # When you instantiate browserchannel, you specify a function which gets called
    # with each session that connects. I'll proxy that function call to a local function
    # which tests can override.
    @onSession = (session) ->
    # The proxy is inline here. Also, I <3 coffeescript's (@server, @port) -> syntax here.
    # That will automatically set this.server and this.port to the callback arguments.
    # 
    # Actually calling the callback starts the test.
    createServer ((session) => @onSession session), (@server, @port, @bc) =>

      # TODO - This should be exported from lib/server
      @standardHeaders=
        'Content-Type': 'text/plain'
        'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate'
        'Pragma': 'no-cache'
        'Expires': 'Fri, 01 Jan 1990 00:00:00 GMT'
        'X-Content-Type-Options': 'nosniff'

      # I'll add a couple helper methods for tests to easily message the server.
      @get = (path, callback) =>
        http.get {host:'localhost', path, @port}, callback

      @post = (path, data, callback) =>
        req = http.request {method:'POST', host:'localhost', path, @port}, callback
        req.end data

      # One of the most common tasks in tests is to create a new session for
      # some reason. @connect is a little helper method for that. It simply sends the
      # http POST to create a new session and calls the callback when the session has been
      # created by the server.
      #
      # It also makes @onSession throw an error - very few tests need multiple sessions,
      # so I special case them when they do.
      #
      # Its kind of annoying - for a lot of tests I need to do custom logic in the @post
      # handler *and* custom logic in @onSession. So, callback can be an object specifying
      # callbacks for each if you want that. Its a shame though, it makes this function
      # kinda ugly :/
      @connect = (callback) =>
        # This connect helper method is only useful if you don't care about the initial
        # post response.
        @post '/channel/bind?VER=8&RID=1000&t=1', 'count=0'

        @onSession = (@session) =>
          @onSession = -> throw new Error 'onSession() called - I didn\'t expect another session to be created'
          # Keep this bound. I think there's a fancy way to do this in coffeescript, but
          # I'm not sure what it is.
          callback.call this

      # Finally, start the test.
      callback()

  tearDown: (callback) ->
    # #### tearDown
    #
    # This is called after each tests is done. We'll tear down the server we just created.
    #
    # The next test is run once the callback is called. I could probably chain the next
    # test without waiting for close(), but then its possible that an exception thrown
    # in one test will appear after the next test has started running. Its easier to debug
    # like this.
    @server.on 'close', callback
    @server.close()
  
  # The server hosts the client-side javascript at /channel.js. It should have headers set to tell
  # browsers its javascript.
  #
  # Its self contained, with no dependancies on anything. It would be nice to test it as well,
  # but we'll do that elsewhere.
  'The javascript is hosted at channel/bcsocket.js': (test) ->
    @get '/channel/bcsocket.js', (response) ->
      test.strictEqual response.statusCode, 200
      test.strictEqual response.headers['content-type'], 'application/javascript'
      test.ok response.headers['etag']
      buffer response, (data) ->
        # Its about 47k. If the size changes too drastically, I want to know about it.
        test.ok data.length > 45000, "Client is unusually small (#{data.length} bytes)"
        test.ok data.length < 50000, "Client is bloaty (#{data.length} bytes)"
        test.done()

  # # Testing channel tests
  #
  # The first thing a client does when it connects is issue a GET on /test/?mode=INIT.
  # The server responds with an array of [basePrefix or null,blockedPrefix or null]. Blocked
  # prefix isn't supported by node-browerchannel and by default no basePrefix is set. So with no
  # options specified, this GET should return [null,null].
  'GET /test/?mode=INIT with no baseprefix set returns [null, null]': (test) ->
    @get '/channel/test?VER=8&MODE=init', (response) ->
      test.strictEqual response.statusCode, 200
      buffer response, (data) ->
        test.strictEqual data, '[null,null]'
        test.done()

  # If a basePrefix is set in the options, make sure the server returns it.
  'GET /test/?mode=INIT with a basePrefix set returns [basePrefix, null]': (test) ->
    # You can specify a bunch of host prefixes. If you do, the server will randomly pick between them.
    # I don't know if thats actually useful behaviour, but *shrug*
    # I should probably write a test to make sure all host prefixes will be chosen from time to time.
    createServer hostPrefixes:['chan'], (->), (server, port) ->
      http.get {path:'/channel/test?VER=8&MODE=init', host: 'localhost', port: port}, (response) ->
        test.strictEqual response.statusCode, 200
        buffer response, (data) ->
          test.strictEqual data, '["chan",null]'
          # I'm being slack here - the server might not close immediately. I could make test.done()
          # dependant on it, but I can't be bothered.
          server.close()
          test.done()

  # Setting a custom url endpoint to bind node-browserchannel to should make it respond at that url endpoint
  # only.
  'The test channel responds at a bound custom endpoint': (test) ->
    createServer base:'/foozit', (->), (server, port) ->
      http.get {path:'/foozit/test?VER=8&MODE=init', host: 'localhost', port: port}, (response) ->
        test.strictEqual response.statusCode, 200
        buffer response, (data) ->
          test.strictEqual data, '[null,null]'
          server.close()
          test.done()
  
  # Some people will miss out on the leading slash in the URL when they bind browserchannel to a custom
  # url. That should work too.
  'binding the server to a custom url without a leading slash works': (test) ->
    createServer base:'foozit', (->), (server, port) ->
      http.get {path:'/foozit/test?VER=8&MODE=init', host: 'localhost', port: port}, (response) ->
        test.strictEqual response.statusCode, 200
        buffer response, (data) ->
          test.strictEqual data, '[null,null]'
          server.close()
          test.done()
  
  # Its tempting to think that you need a trailing slash on your URL prefix as well. You don't, but that should
  # work too.
  'binding the server to a custom url with a trailing slash works': (test) ->
    # Some day, the copy+paste police are gonna get me. I don't feel *so* bad doing it for tests though, because
    # it helps readability.
    createServer base:'foozit/', (->), (server, port) ->
      http.get {path:'/foozit/test?VER=8&MODE=init', host: 'localhost', port: port}, (response) ->
        test.strictEqual response.statusCode, 200
        buffer response, (data) ->
          test.strictEqual data, '[null,null]'
          server.close()
          test.done()

  # You can control the CORS header ('Access-Control-Allow-Origin') using options.cors.
  'CORS header is not sent if its not set in the options': (test) ->
    @get '/channel/test?VER=8&MODE=init', (response) ->
      test.strictEqual response.headers['access-control-allow-origin'], undefined
      test.done()

  'CORS header is sent during the initial phase if its set in the options': (test) ->
    createServer cors:'foo.com', (->), (server, port) ->
      http.get {path:'/channel/test?VER=8&MODE=init', host: 'localhost', port: port}, (response) ->
        test.strictEqual response.headers['access-control-allow-origin'], 'foo.com'
        server.close()
        test.done()

  'CORS header is set on the backchannel response': (test) ->
    server = port = null

    sessionCreated = (session) ->
      # Make the backchannel flush as soon as its opened
      session.send "flush"

      req = http.get {path:"/channel/bind?VER=8&RID=rpc&SID=#{session.id}&AID=0&TYPE=xmlhttp&CI=0", host:'localhost', port:port}, (res) =>
        test.strictEqual res.headers['access-control-allow-origin'], 'foo.com'
        req.abort()
        server.close()
        test.done()
    
    createServer cors:'foo.com', sessionCreated, (_server, _port) ->
      [server, port] = [_server, _port]

      req = http.request {method:'POST', path:'/channel/bind?VER=8&RID=1000&t=1', host:'localhost', port:port}, (res) =>
      req.end 'count=0'

  'Additional headers can be specified in the options': (test) ->
    createServer headers:{'X-Foo':'bar'}, (->), (server, port) ->
      http.get {path:'/channel/test?VER=8&MODE=init', host: 'localhost', port: port}, (response) ->
        test.strictEqual response.headers['x-foo'], 'bar'
        server.close()
        test.done()

  # Interestingly, the CORS header isn't required for old IE (type=html) requests because they're loaded using
  # iframes anyway. (Though this should really be tested).

 
  # node-browserchannel is only responsible for URLs with the specified (or default) prefix. If a request
  # comes in for a URL outside of that path, it should be passed along to subsequent connect middleware.
  #
  # I've set up the createServer() method above to send 'Other middleware' if browserchannel passes
  # the response on to the next handler.
  'getting a url outside of the bound range gets passed to other middleware': (test) ->
    @get '/otherapp', (response) ->
      test.strictEqual response.statusCode, 200
      buffer response, (data) ->
        test.strictEqual data, 'Other middleware'
        test.done()
  
  # I decided to make URLs inside the bound range return 404s directly. I can't guarantee that no future
  # version of node-browserchannel won't add more URLs in the zone, so its important that users don't decide
  # to start using arbitrary other URLs under channel/.
  #
  # That design decision makes it impossible to add a custom 404 page to /channel/FOO, but I don't think thats a
  # big deal.
  'getting a wacky url inside the bound range returns 404': (test) ->
    @get '/channel/doesnotexist', (response) ->
      test.strictEqual response.statusCode, 404
      test.done()

  # For node-browserchannel, we also accept JSON in forward channel POST data. To tell the client that
  # this is supported, we add an `X-Accept: application/json; application/x-www-form-urlencoded` header
  # in phase 1 of the test API.
  'The server sends accept:JSON header during test phase 1': (test) ->
    @get '/channel/test?VER=8&MODE=init', (res) ->
      test.strictEqual res.headers['x-accept'], 'application/json; application/x-www-form-urlencoded'
      test.done()

  # All the standard headers should be sent along with X-Accept
  'The server sends standard headers during test phase 1': (test) ->
    @get '/channel/test?VER=8&MODE=init', (res) =>
      test.strictEqual res.headers[k.toLowerCase()].toLowerCase(), v.toLowerCase() for k,v of @standardHeaders
      test.done()

  # ## Testing phase 2
  #
  # I should really sort the above tests better.
  # 
  # Testing phase 2 the client GETs /channel/test?VER=8&TYPE= [html / xmlhttp] &zx=558cz3evkwuu&t=1 [&DOMAIN=xxxx]
  #
  # The server sends '11111' <2 second break> '2'. If you use html encoding instead, the server sends the client
  # a webpage which calls:
  #
  #     document.domain='mail.google.com';
  #     parent.m('11111');
  #     parent.m('2');
  #     parent.d();
  'Getting test phase 2 returns 11111 then 2': do ->
    makeTest = (type, message1, message2) -> (test) ->
      @get "/channel/test?VER=8&TYPE=#{type}", (response) ->
        test.strictEqual response.statusCode, 200
        expect response, message1, ->
          # Its important to make sure that message 2 isn't sent too soon (<2 seconds).
          # We'll advance the server's clock forward by just under 2 seconds and then wait a little bit
          # for messages from the client. If we get a message during this time, throw an error.
          response.on 'data', f = -> throw new Error 'should not get more data so early'
          timer.wait 1999, ->
            soon ->
              response.removeListener 'data', f
              timer.wait 1, ->
                expect response, message2, ->
                  response.once 'end', -> test.done()

    'xmlhttp': makeTest 'xmlhttp', '11111', '2'

    # I could write this test using JSDom or something like that, and parse out the HTML correctly.
    # ... but it would be way more complicated (and no more correct) than simply comparing the resulting
    # strings.
    'html': makeTest('html',
      # These HTML responses are identical to what I'm getting from google's servers. I think the seemingly
      # random sequence is just so network framing doesn't try and chunk up the first packet sent to the server
      # or something like that.
      """<html><body><script>try {parent.m("11111")} catch(e) {}</script>\n#{ieJunk}""",
      '''<script>try {parent.m("2")} catch(e) {}</script>
<script>try  {parent.d(); }catch (e){}</script>\n''')

    # If a client is connecting with a host prefix, the server sets the iframe's document.domain to match
    # before sending actual data.
    'html with a host prefix': makeTest('html&DOMAIN=foo.bar.com',
      # I've made a small change from google's implementation here. I'm using double quotes `"` instead of
      # single quotes `'` because its easier to encode. (I can't just wrap the string in quotes because there
      # are potential XSS vulnerabilities if I do that).
      """<html><body><script>try{document.domain="foo.bar.com";}catch(e){}</script>
<script>try {parent.m("11111")} catch(e) {}</script>\n#{ieJunk}""",
      '''<script>try {parent.m("2")} catch(e) {}</script>
<script>try  {parent.d(); }catch (e){}</script>\n''')
  
  # IE doesn't parse the HTML in the response unless the Content-Type is text/html
  'Using type=html sets Content-Type: text/html': (test) ->
    r = @get "/channel/test?VER=8&TYPE=html", (response) ->
      test.strictEqual response.headers['content-type'], 'text/html'
      r.abort()
      test.done()

  # IE should also get the standard headers
  'Using type=html gets the standard headers': (test) ->
    r = @get "/channel/test?VER=8&TYPE=html", (response) =>
      for k, v of @standardHeaders when k isnt 'Content-Type'
        test.strictEqual response.headers[k.toLowerCase()].toLowerCase(), v.toLowerCase()
      r.abort()
      test.done()

  # node-browserchannel is only compatible with browserchannel client version 8. I don't know whats changed
  # since old versions (maybe v6 would be easy to support) but I don't care. If the client specifies
  # an old version, we'll die with an error.
  # The alternate phase 2 URL style should have the same behaviour if the version is old or unspecified.
  #
  # Google's browserchannel server still works if you miss out on specifying the version - it defaults
  # to version 1 (which maybe didn't have version numbers in the URLs). I'm kind of impressed that
  # all that code still works.
  'Getting /test/* without VER=8 returns an error': do ->
    # All these tests look 95% the same. Instead of writing the same test all those times, I'll use this
    # little helper method to generate them.
    check400 = (path) -> (test) ->
      @get path, (response) ->
        test.strictEqual response.statusCode, 400
        test.done()

    'phase 1, ver 7': check400 '/channel/test?VER=7&MODE=init'
    'phase 1, no version': check400 '/channel/test?MODE=init'
    'phase 2, ver 7, xmlhttp': check400 '/channel/test?VER=7&TYPE=xmlhttp'
    'phase 2, no version, xmlhttp': check400 '/channel/test?TYPE=xmlhttp'
    # For HTTP connections (IE), the error is sent a different way. Its kinda complicated how the error
    # is sent back, so for now I'm just going to ignore checking it.
    'phase 2, ver 7, http': check400 '/channel/test?VER=7&TYPE=html'
    'phase 2, no version, http': check400 '/channel/test?TYPE=html'
  

  # > At the moment the server expects the client will add a zx=###### query parameter to all requests.
  # The server isn't strict about this, so I'll ignore it in the tests for now.

  # # Server connection tests
  
  # These tests make server sessions by crafting raw HTTP queries. I'll make another set of
  # tests later which spam the server with a million fake clients.
  #
  # To start with, simply connect to a server using the BIND API. A client sends a server a few parameters:
  #
  # - **CVER**: Client application version
  # - **RID**: Client-side generated random number, which is the initial sequence number for the
  #   client's requests.
  # - **VER**: Browserchannel protocol version. Must be 8.
  # - **t**: The connection attempt number. This is currently ignored by the BC server. (I'm not sure
  #   what google's implementation does with this).
  'The server makes a new session if the client POSTs the right connection stuff': (test) ->
    id = null
    # When a request comes in, we should get the new session through the server API.
    #
    # We need this session in order to find out the session ID, which should match up with part of the
    # server's response.
    @onSession = (session) ->
      test.ok session
      test.strictEqual typeof session.id, 'string'
      test.strictEqual session.state, 'init'
      test.strictEqual session.appVersion, '99'
      test.deepEqual session.address, '127.0.0.1'
      test.strictEqual typeof session.headers, 'object'

      id = session.id
      session.on 'map', -> throw new Error 'Should not have received data'

    # The client starts a BC connection by POSTing to /bind? with no session ID specified.
    # The client can optionally send data here, but in this case it won't (hence the `count=0`).
    @post '/channel/bind?VER=8&RID=1000&CVER=99&t=1&junk=asdfasdf', 'count=0', (res) =>
      expected = (JSON.stringify [[0, ['c', id, null, 8]]]) + '\n'
      buffer res, (data) ->
        # Even for old IE clients, the server responds in length-prefixed JSON style.
        test.strictEqual data, "#{expected.length}\n#{expected}"
        test.expect 7
        test.done()
  
  # Once a client's session id is sent, the session moves to the `ok` state. This happens after onSession is
  # called (so onSession can send messages to the client immediately).
  #
  # I'm starting to use the @connect method here, which just POSTs locally to create a session, sets @session and
  # calls its callback.
  'A session has state=ok after onSession returns': (test) -> @connect ->
    @session.on 'state changed', (newState, oldState) =>
      test.strictEqual oldState, 'init'
      test.strictEqual newState, 'ok'
      test.strictEqual @session.state, 'ok'
      test.done()

  # The CVER= property is optional during client connections. If its left out, session.appVersion is
  # null.
  'A session connects ok even if it doesnt specify an app version': (test) ->
    id = null
    @onSession = (session) ->
      test.strictEqual session.appVersion, null
      id = session.id
      session.on 'map', -> throw new Error 'Should not have received data'

    @post '/channel/bind?VER=8&RID=1000&t=1&junk=asdfasdf', 'count=0', (res) =>
      expected = (JSON.stringify [[0, ['c', id, null, 8]]]) + '\n'
      buffer res, (data) ->
        test.strictEqual data, "#{expected.length}\n#{expected}"
        test.expect 2
        test.done()

  # Once again, only VER=8 works.
  'Connecting with a version thats not 8 breaks': do ->
    # This will POST to the requested path and make sure the response sets status 400
    check400 = (path) -> (test) ->
      @post path, 'count=0', (response) ->
        test.strictEqual response.statusCode, 400
        test.done()
    
    'no version': check400 '/channel/bind?RID=1000&t=1'
    'previous version': check400 '/channel/bind?VER=7&RID=1000&t=1'

  # This time, we'll send a map to the server during the initial handshake. This should be received
  # by the server as normal.
  'The client can post messages to the server during initialization': (test) ->
    @onSession = (session) ->
      session.on 'map', (data) ->
        test.deepEqual data, {k:'v'}
        test.done()

    @post '/channel/bind?VER=8&RID=1000&t=1', 'count=1&ofs=0&req0_k=v', (res) =>
  
  # The data received by the server should be properly URL decoded and whatnot.
  'Server messages are properly URL decoded': (test) ->
    @onSession = (session) ->
      session.on 'map', (data) ->
        test.deepEqual data, {"_int_^&^%#net":'hi"there&&\nsam'}
        test.done()

    @post('/channel/bind?VER=8&RID=1000&t=1',
      'count=1&ofs=0&req0__int_%5E%26%5E%25%23net=hi%22there%26%26%0Asam', ->)

  # After a client connects, it can POST data to the server using URL-encoded POST data. This data
  # is sent by POSTing to /bind?SID=....
  #
  # The data looks like this:
  #
  # count=5&ofs=1000&req0_KEY1=VAL1&req0_KEY2=VAL2&req1_KEY3=req1_VAL3&...
  'The client can post messages to the server after initialization': (test) -> @connect ->
    @session.on 'map', (data) ->
      test.deepEqual data, {k:'v'}
      test.done()

    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_k=v', (res) =>
  
  # When the server gets a forwardchannel request, it should reply with a little array saying whats
  # going on.
  'The server acknowledges forward channel messages correctly': (test) -> @connect ->
    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_k=v', (res) =>
      readLengthPrefixedJSON res, (data) =>
        # The server responds with [backchannelMissing ? 0 : 1, lastSentAID, outstandingBytes]
        test.deepEqual data, [0, 0, 0]
        test.done()

  # If the server has an active backchannel, it responds to forward channel requests notifying the client
  # that the backchannel connection is alive and well.
  'The server tells the client if the backchannel is alive': (test) -> @connect ->
    # This will fire up a backchannel connection to the server.
    req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp", (res) =>
      # The client shouldn't get any data through the backchannel.
      res.on 'data', -> throw new Error 'Should not get data through backchannel'

    # Unfortunately, the GET request is sent *after* the POST, so we have to wrap the
    # post in a timeout to make sure it hits the server after the backchannel connection is
    # established.
    soon =>
      @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_k=v', (res) =>
        readLengthPrefixedJSON res, (data) =>
          # This time, we get a 1 as the first argument because the backchannel connection is
          # established.
          test.deepEqual data, [1, 0, 0]
          # The backchannel hasn't gotten any data yet. It'll spend 15 seconds or so timing out
          # if we don't abort it manually.

          # As of nodejs 0.6, if you abort() a connection, it can emit an error.
          req.on 'error', ->
          req.abort()
          test.done()

  # The forward channel response tells the client how many unacknowledged bytes there are, so it can decide
  # whether or not it thinks the backchannel is dead.
  'The server tells the client how much unacknowledged data there is in the post response': (test) -> @connect ->
    process.nextTick =>
      # I'm going to send a few messages to the client and acknowledge the first one in a post response.
      @session.send 'message 1'
      @session.send 'message 2'
      @session.send 'message 3'

    # We'll make a backchannel and get the data
    req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
      readLengthPrefixedJSON res, (data) =>
        # After the data is received, I'll acknowledge the first message using an empty POST
        @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=1", 'count=0', (res) =>
          readLengthPrefixedJSON res, (data) =>
            # We should get a response saying "The backchannel is connected", "The last message I sent was 3"
            # "messages 2 and 3 haven't been acknowledged, here's their size"
            test.deepEqual data, [1, 3, 25]
            req.abort()
            test.done()
  
  # When the user calls send(), data is queued by the server and sent into the next backchannel connection.
  #
  # The server will use the initial establishing connection if thats available, or it'll send it the next
  # time the client opens a backchannel connection.
  'The server returns data on the initial connection when send is called immediately': (test) ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]
    @onSession = (@session) =>
      @session.send testData

    # I'm not using @connect because we need to know about the response to the first POST.
    @post '/channel/bind?VER=8&RID=1000&t=1', 'count=0', (res) =>
      readLengthPrefixedJSON res, (data) =>
        test.deepEqual data, [[0, ['c', @session.id, null, 8]], [1, testData]]
        test.done()

  'The server escapes tricky characters before sending JSON over the wire': (test) ->
    testData = {'a': 'hello\u2028\u2029there\u2028\u2029'}
    @onSession = (@session) =>
      @session.send testData

    # I'm not using @connect because we need to know about the response to the first POST.
    @post '/channel/bind?VER=8&RID=1000&t=1', 'count=0', (res) =>
      readLengthPrefixedString res, (data) =>
        test.deepEqual data, """[[0,["c","#{@session.id}",null,8]],[1,{"a":"hello\\u2028\\u2029there\\u2028\\u2029"}]]\n"""
        test.done()

  'The server buffers data if no backchannel is available': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    # The first response to the server is sent after this method returns, so if we send the data
    # in process.nextTick, it'll get buffered.
    process.nextTick =>
      @session.send testData

      req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        readLengthPrefixedJSON res, (data) =>
          test.deepEqual data, [[1, testData]]
          req.abort()
          test.done()
  
  # This time, we'll fire up the back channel first (and give it time to get established) _then_
  # send data through the session.
  'The server returns data through the available backchannel when send is called later': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    # Fire off the backchannel request as soon as the client has connected
    req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) ->

      #res.on 'data', (chunk) -> console.warn chunk.toString()
      readLengthPrefixedJSON res, (data) ->
        test.deepEqual data, [[1, testData]]
        req.abort()
        test.done()

    # Send the data outside of the get block to make sure it makes it through.
    soon => @session.send testData
  
  # The server should call the send callback once the data has been confirmed by the client.
  #
  # We'll try sending three messages to the client. The first message will be sent during init and the
  # third message will not be acknowledged. Only the first two message callbacks should get called.
  'The server calls send callback once data is acknowledged': (test) -> @connect ->
    lastAck = null

    @session.send [1], ->
      test.strictEqual lastAck, null
      lastAck = 1

    process.nextTick =>
      @session.send [2], ->
        test.strictEqual lastAck, 1
        # I want to give the test time to die
        soon -> test.done()

      # This callback should actually get called with an error after the client times out. ... but I'm not
      # giving timeouts a chance to run.
      @session.send [3], -> throw new Error 'Should not call unacknowledged send callback'

      req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=1&TYPE=xmlhttp&CI=0", (res) =>
        readLengthPrefixedJSON res, (data) =>
          test.deepEqual data, [[2, [2]], [3, [3]]]

          # Ok, now we'll only acknowledge the second message by sending AID=2
          @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=2", 'count=0', (res) =>
            req.abort()

  # If there's a proxy in the way which chunks up responses before sending them on, the client adds a
  # &CI=1 argument on the backchannel. This causes the server to end the HTTP query after each message
  # is sent, so the data is sent to the session.
  'The backchannel is closed after each packet if chunking is turned off': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    process.nextTick =>
      @session.send testData

      # Instead of the usual CI=0 we're passing CI=1 here.
      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=1", (res) =>
        readLengthPrefixedJSON res, (data) =>
          test.deepEqual data, [[1, testData]]

        res.on 'end', -> test.done()

  # Normally, the server doesn't close the connection after each backchannel message.
  'The backchannel is left open if CI=0': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    process.nextTick =>
      @session.send testData

      req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        readLengthPrefixedJSON res, (data) =>
          test.deepEqual data, [[1, testData]]

        # After receiving the data, the client shouldn't close the connection. (At least, not unless
        # it times out naturally).
        res.on 'end', -> throw new Error 'connection should have stayed open'

        soon ->
          res.removeAllListeners 'end'
          req.abort()
          test.done()

  # On IE, the data is all loaded using iframes. The backchannel spits out data using inline scripts
  # in an HTML page.
  #
  # I've written this test separately from the tests above, but it would really make more sense
  # to rerun the same set of tests in both HTML and XHR modes to make sure the behaviour is correct
  # in both instances.
  'The server gives the client correctly formatted backchannel data if TYPE=html': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    process.nextTick =>
      @session.send testData

      # The type is specified as an argument here in the query string. For this test, I'm making
      # CI=1, because the test is easier to write that way.
      #
      # In truth, I don't care about IE support as much as support for modern browsers. This might
      # be a mistake.. I'm not sure. IE9's XHR support should work just fine for browserchannel,
      # though google's BC client doesn't use it.
      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=html&CI=1", (res) =>
        expect res,
          # Interestingly, google doesn't double-encode the string like this. Instead of turning
          # quotes `"` into escaped quotes `\"`, it uses unicode encoding to turn them into \42 and
          # stuff like that. I'm not sure why they do this - it produces the same effect in IE8.
          # I should test it in IE6 and see if there's any problems.
          """<html><body><script>try {parent.m(#{JSON.stringify JSON.stringify([[1, testData]]) + '\n'})} catch(e) {}</script>
#{ieJunk}<script>try  {parent.d(); }catch (e){}</script>\n""", =>
            # Because I'm lazy, I'm going to chain on a test to make sure CI=0 works as well.
            data2 = {other:'data'}
            @session.send data2
            # I'm setting AID=1 here to indicate that the client has seen array 1.
            req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=1&TYPE=html&CI=0", (res) =>
              expect res,
                """<html><body><script>try {parent.m(#{JSON.stringify JSON.stringify([[2, data2]]) + '\n'})} catch(e) {}</script>
#{ieJunk}""", =>
                  req.abort()
                  test.done()
  
  # If there's a basePrefix set, the returned HTML sets `document.domain = ` before sending messages.
  # I'm super lazy, and just copy+pasting from the test above. There's probably a way to factor these tests
  # nicely, but I'm not in the mood to figure it out at the moment.
  'The server sets the domain if we have a domain set': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    process.nextTick =>
      @session.send testData
      # This time we're setting DOMAIN=X, and the response contains a document.domain= block. Woo.
      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=html&CI=1&DOMAIN=foo.com", (res) =>
        expect res,
          """<html><body><script>try{document.domain=\"foo.com\";}catch(e){}</script>
<script>try {parent.m(#{JSON.stringify JSON.stringify([[1, testData]]) + '\n'})} catch(e) {}</script>
#{ieJunk}<script>try  {parent.d(); }catch (e){}</script>\n""", =>
            data2 = {other:'data'}
            @session.send data2
            req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=1&TYPE=html&CI=0&DOMAIN=foo.com", (res) =>
              expect res,
                # Its interesting - in the test channel, the ie junk comes right after the document.domain= line,
                # but in a backchannel like this it comes after. The behaviour here is the same in google's version.
                #
                # I'm not sure if its actually significant though.
                """<html><body><script>try{document.domain=\"foo.com\";}catch(e){}</script>
<script>try {parent.m(#{JSON.stringify JSON.stringify([[2, data2]]) + '\n'})} catch(e) {}</script>
#{ieJunk}""", =>
                  req.abort()
                  test.done()

  # If a client thinks their backchannel connection is closed, they might open a second backchannel connection.
  # In this case, the server should close the old one and resume sending stuff using the new connection.
  'The server closes old backchannel connections': (test) -> @connect ->
    testData = ['hello', 'there', null, 1000, {}, [], [555]]

    process.nextTick =>
      @session.send testData

      # As usual, we'll get the sent data through the backchannel connection. The connection is kept open...
      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        readLengthPrefixedJSON res, (data) =>
          # ... and the data has been read. Now we'll open another connection and check that the first connection
          # gets closed.

          req2 = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=1&TYPE=xmlhttp&CI=0", (res2) =>

          res.on 'end', ->
            req2.on 'error', ->
            req2.abort()
            test.done()

  # The client attaches a sequence number (*RID*) to every message, to make sure they don't end up out-of-order at
  # the server's end.
  #
  # We'll purposefully send some messages out of order and make sure they're held and passed through in order.
  #
  # Gogo gadget reimplementing TCP.
  'The server orders forwardchannel messages correctly using RIDs': (test) -> @connect ->
    # @connect sets RID=1000.

    # We'll send 2 maps, the first one will be {v:1} then {v:0}. They should be swapped around by the server.
    lastVal = 0

    @session.on 'map', (map) ->
      test.strictEqual map.v, "#{lastVal++}", 'messages arent reordered in the server'
      test.done() if map.v == '2'
  
    # First, send `[{v:2}]`
    @post "/channel/bind?VER=8&RID=1002&SID=#{@session.id}&AID=0", 'count=1&ofs=2&req0_v=2', (res) =>
    # ... then `[{v:0}, {v:1}]` a few MS later.
    soon =>
      @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=2&ofs=0&req0_v=0&req1_v=1', (res) =>
  
  # Again, think of browserchannel as TCP on top of UDP...
  'Repeated forward channel messages are discarded': (test) -> @connect ->
    gotMessage = false
    # The map must only be received once.
    @session.on 'map', (map) ->
      if gotMessage == false
        gotMessage = true
      else
        throw new Error 'got map twice'
  
    # POST the maps twice.
    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_v=0', (res) =>
    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_v=0', (res) =>

    # Wait 50 milliseconds for the map to (maybe!) be received twice, then pass.
    soon ->
      test.strictEqual gotMessage, true
      test.done()

  # The client can retry failed forwardchannel requests with additional maps. We may have gotten the failed
  # request. An error could have occurred when we reply.
  'Repeat forward channel messages can contain extra maps': (test) -> @connect ->
    # We should get exactly 2 maps, {v:0} then {v:1}
    maps = []
    @session.on 'map', (map) ->
      maps.push map

    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_v=0', (res) =>
    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=2&ofs=0&req0_v=0&req1_v=1', (res) =>

    soon ->
      test.deepEqual maps, [{v:0}, {v:1}]
      test.done()

  # With each request to the server, the client tells the server what array it saw last through the AID= parameter.
  #
  # If a client sends a subsequent backchannel request with an old AID= set, that means the client never saw the arrays
  # the server has previously sent. So, the server should resend them.
  'The server resends lost arrays if the client asks for them': (test) -> @connect ->
    process.nextTick =>
      @session.send [1,2,3]
      @session.send [4,5,6]

      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        readLengthPrefixedJSON res, (data) =>
          test.deepEqual data, [[1, [1,2,3]], [2, [4,5,6]]]

          # We'll resend that request, pretending that the client never saw the second array sent (`[4,5,6]`)
          req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=1&TYPE=xmlhttp&CI=0", (res) =>
            readLengthPrefixedJSON res, (data) =>
              test.deepEqual data, [[2, [4,5,6]]]
              # We don't need to abort the first connection because the server should close it.
              req.abort()
              test.done()

  # If you sleep your laptop or something, by the time you open it again the server could have timed out your session
  # so your session ID is invalid. This will also happen if the server gets restarted or something like that.
  #
  # The server should respond to any query requesting a nonexistant session ID with 400 and put 'Unknown SID'
  # somewhere in the message. (Actually, the BC client test is `indexOf('Unknown SID') > 0` so there has to be something
  # before that text in the message or indexOf will return 0.
  #
  # The google servers also set Unknown SID as the http status code, which is kinda neat. I can't check for that.
  'If a client sends an invalid SID in a request, the server responds with 400 Unknown SID': do ->
    testResponse = (test) -> (res) ->
      test.strictEqual res.statusCode, 400
      buffer res, (data) ->
        test.ok data.indexOf('Unknown SID') > 0
        test.done()

    'backChannel': (test) -> @get "/channel/bind?VER=8&RID=rpc&SID=madeup&AID=0&TYPE=xmlhttp&CI=0", testResponse(test)
    'forwardChannel': (test) -> @post "/channel/bind?VER=8&RID=1001&SID=junkyjunk&AID=0", 'count=0', testResponse(test)
    # When type=HTML, google's servers still send the same response back to the client. I'm not sure how it detects
    # the error, but it seems to work. So, I'll copy that behaviour.
    'backChannel with TYPE=html': (test) -> @get "/channel/bind?VER=8&RID=rpc&SID=madeup&AID=0&TYPE=html&CI=0", testResponse(test)

  # When a client connects, it can optionally specify its old session ID and array ID. This solves the old IRC
  # ghosting problem - if the old session hasn't timed out on the server yet, you can temporarily be in a state where
  # multiple connections represent the same user.
  'If a client disconnects then reconnects, specifying OSID= and OAID=, the old session is destroyed': (test) ->
    @post '/channel/bind?VER=8&RID=1000&t=1', 'count=0', (res) =>

    # I want to check the following things:
    #
    # - on 'close' is called on the first session
    # - onSession is called with the second session
    # - on 'close' is called before the second session is created
    #
    # Its kinda gross managing all that state in one function...
    @onSession = (session1) =>
      # As soon as the client has connected, we'll fire off a new connection claiming the previous session is old.
      @post "/channel/bind?VER=8&RID=2000&t=1&OSID=#{session1.id}&OAID=0", 'count=0', (res) =>

      c1Closed = false
      session1.on 'close', ->
        c1Closed = true

      # Once the first client has connected, I'm replacing @onSession so the second session's state can be handled
      # separately.
      @onSession = (session2) ->
        test.ok c1Closed
        test.strictEqual session1.state, 'closed'

        test.done()

  # The server might have already timed out an old connection. In this case, the OSID is ignored.
  'The server ignores OSID and OAID if the named session doesnt exist': (test) ->
    @post "/channel/bind?VER=8&RID=2000&t=1&OSID=doesnotexist&OAID=0", 'count=0', (res) =>

    # So small & pleasant!
    @onSession = (session) =>
      test.ok session
      test.done()

  # OAID is set in the ghosted connection as a final attempt to flush arrays.
  'The server uses OAID to confirm arrays in the old session before closing it': (test) -> @connect ->
    # We'll follow the same pattern as the first callback test waay above. We'll send three messages, one
    # in the first callback and two after. We'll pretend that just the first two messages made it through.
    lastMessage = null

    # We'll create a new session in a moment when we POST with OSID and OAID.
    @onSession = ->

    @session.send 1, (error) ->
      test.ifError error
      test.strictEqual lastMessage, null
      lastMessage = 1

    # The final message callback should get called after the close event fires
    @session.on 'close', ->
      test.strictEqual lastMessage, 2

    process.nextTick =>
      @session.send 2, (error) ->
        test.ifError error
        test.strictEqual lastMessage, 1
        lastMessage = 2

      @session.send 3, (error) ->
        test.ok error
        test.strictEqual lastMessage, 2
        lastMessage = 3
        test.strictEqual error.message, 'Reconnected'

        soon ->
          req.abort()
          test.done()

      # And now we'll nuke the session and confirm the first two arrays. But first, its important
      # the client has a backchannel to send data to (confirming arrays before a backchannel is opened
      # to receive them is undefined and probably does something bad)
      req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=1&TYPE=xmlhttp&CI=0", (res) =>

      @post "/channel/bind?VER=8&RID=2000&t=1&OSID=#{@session.id}&OAID=2", 'count=0', (res) =>

  'The session times out after awhile if it doesnt have a backchannel': (test) -> @connect ->
    start = timer.Date.now()
    @session.on 'close', (reason) ->
      test.strictEqual reason, 'Timed out'
      # It should take at least 30 seconds.
      test.ok timer.Date.now() - start >= 30000
      test.done()

    timer.waitAll()

  'The session can be disconnected by firing a GET with TYPE=terminate': (test) -> @connect ->
    # The client doesn't seem to put AID= in here. I'm not sure why - could be a bug in the client.
    @get "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&TYPE=terminate", (res) ->
      # The response should be empty.
      buffer res, (data) -> test.strictEqual data, ''

    @session.on 'close', (reason) ->
      # ... Its a manual disconnect. Is this reason string good enough?
      test.strictEqual reason, 'Disconnected'
      test.done()

  'If a disconnect message reaches the client before some data, the data is still received': (test) -> @connect ->
    # The disconnect message is sent first, but its got a higher RID. It shouldn't be handled until
    # after the data.
    @get "/channel/bind?VER=8&RID=1003&SID=#{@session.id}&TYPE=terminate", (res) ->
    soon =>
      @post "/channel/bind?VER=8&RID=1002&SID=#{@session.id}&AID=0", 'count=1&ofs=1&req0_m=2', (res) =>
      @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", 'count=1&ofs=0&req0_m=1', (res) =>

    maps = []
    @session.on 'map', (data) ->
      maps.push data
    @session.on 'close', (reason) ->
      test.strictEqual reason, 'Disconnected'
      test.deepEqual maps, [{m:1}, {m:2}]
      test.done()

  # There's a slightly different codepath after a backchannel is opened then closed again. I want to make
  # sure it still works in this case.
  # 
  # Its surprising how often this test fails.
  'The session times out if its backchannel is closed': (test) -> @connect ->
    process.nextTick =>
      req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>

      # I'll let the backchannel establish itself for a moment, and then nuke it.
      soon =>
        req.on 'error', ->
        req.abort()
        # It should take about 30 seconds from now to timeout the connection.
        start = timer.Date.now()
        @session.on 'close', (reason) ->
          test.strictEqual reason, 'Timed out'
          test.ok timer.Date.now() - start >= 30000
          test.done()

        # The timer sessionTimeout won't be queued up until after the abort() message makes it
        # to the server. I hate all these delays, but its not easy to write this test without them.
        soon -> timer.waitAll()

  # The server sends a little heartbeat across the backchannel every 20 seconds if there hasn't been
  # any chatter anyway. This keeps the machines en route from evicting the backchannel connection.
  # (noops are ignored by the client.)
  'A heartbeat is sent across the backchannel (by default) every 20 seconds': (test) -> @connect ->
    start = timer.Date.now()

    req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
      readLengthPrefixedJSON res, (msg) ->
        # this really just tests that one heartbeat is sent.
        test.deepEqual msg, [[1, ['noop']]]
        test.ok timer.Date.now() - start >= 20000
        req.abort()
        test.done()

    # Once again, we can't call waitAll() until the request has hit the server.
    soon -> timer.waitAll()

  # So long as the backchannel stays open, the server should just keep sending heartbeats and
  # the session doesn't timeout.
  'A server with an active backchannel doesnt timeout': (test) -> @connect ->
    aid = 1
    req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
      getNextNoop = ->
        readLengthPrefixedJSON res, (msg) ->
          test.deepEqual msg, [[aid++, ['noop']]]
          getNextNoop()
      
      getNextNoop()

    # ... give the backchannel time to get established
    soon ->
      # wait 500 seconds. In that time, we'll get 25 noops.
      timer.wait 500 * 1000, ->
        # and then give the last noop a chance to get sent
        soon ->
          test.strictEqual aid, 26
          req.abort()
          test.done()

    #req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>

  # The send callback should be called _no matter what_. That means if a connection times out, it should
  # still be called, but we'll pass an error into the callback.
  'The server calls send callbacks with an error':
    'when the session times out': (test) -> @connect ->
      # It seems like this message shouldn't give an error, but it does because the client never confirms that
      # its received it.
      @session.send 'hello there', (error) ->
        test.ok error
        test.strictEqual error.message, 'Timed out'

      process.nextTick =>
        @session.send 'Another message', (error) ->
          test.ok error
          test.strictEqual error.message, 'Timed out'
          test.expect 4
          test.done()

        timer.waitAll()

    'when the session is ghosted': (test) -> @connect ->
      # As soon as the client has connected, we'll fire off a new connection claiming the previous session is old.
      @post "/channel/bind?VER=8&RID=2000&t=1&OSID=#{@session.id}&OAID=0", 'count=0', (res) =>

      @session.send 'hello there', (error) ->
        test.ok error
        test.strictEqual error.message, 'Reconnected'

      process.nextTick =>
        @session.send 'hi', (error) ->
          test.ok error
          test.strictEqual error.message, 'Reconnected'
          test.expect 4
          test.done()

      # Ignore the subsequent connection attempt
      @onSession = ->

    # The server can also abandon a connection by calling .abort(). Again, this should trigger error callbacks.
    'when the session is closed by the server': (test) -> @connect ->

      @session.send 'hello there', (error) ->
        test.ok error
        test.strictEqual error.message, 'foo'

      process.nextTick =>
        @session.send 'hi', (error) ->
          test.ok error
          test.strictEqual error.message, 'foo'
          test.expect 4
          test.done()

        @session.close 'foo'

    # Finally, the server closes a connection when the client actively closes it (by firing a GET with TYPE=terminate)
    'when the server gets a disconnect request': (test) -> @connect ->
      @session.send 'hello there', (error) ->
        test.ok error
        test.strictEqual error.message, 'Disconnected'

      process.nextTick =>
        @session.send 'hi', (error) ->
          test.ok error
          test.strictEqual error.message, 'Disconnected'
          test.expect 4
          test.done()

      @get "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&TYPE=terminate", (res) ->

  'If a session has close() called with no arguments, the send error message says "closed"': (test) -> @connect ->
    @session.send 'hello there', (error) ->
      test.ok error
      test.strictEqual error.message, 'closed'
      test.done()

    @session.close()

  # stop() sends a message to the client saying basically 'something is wrong, stop trying to
  # connect'. It triggers a special error in the client, and the client will stop trying to reconnect
  # at this point.
  #
  # The server can still send and receive messages after the stop message has been sent. But the client
  # probably won't receive them.
  #
  # Stop takes a callback which is called when the stop message has been **sent**. (The client never confirms
  # that it has received the message).
  'Calling stop() sends the stop command to the client':
    'during init': (test) ->
      @post '/channel/bind?VER=8&RID=1000&t=1', 'count=0', (res) =>
        readLengthPrefixedJSON res, (data) =>
          test.deepEqual data, [[0, ['c', @session.id, null, 8]], [1, ['stop']]]
          test.done()

      @onSession = (@session) =>
        @session.stop()

    'after init': (test) -> @connect ->
      # This test is similar to the test above, but I've put .stop() in a setTimeout.
      req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        readLengthPrefixedJSON res, (data) ->
          test.deepEqual data, [[1, ['stop']]]
          req.abort()
          test.done()

      soon => @session.stop()

  'A callback passed to stop is called once stop is sent to the client':
    # ... because the stop message will be sent to the client in the initial connection
    'during init': (test) -> @connect ->
      @session.stop ->
        test.done()

    'after init': (test) -> @connect ->
      process.nextTick =>
        req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
          readLengthPrefixedJSON res, (data) ->
            test.deepEqual data, [[1, ['stop']]]
            test.expect 2
            req.abort()
            test.done()

        @session.stop ->
          # Just a noop test to increase the 'things tested' count
          test.ok 1

  # close() aborts the session immediately. After calling close, subsequent requests to the session
  # should fail with unknown SID errors.
  'session.close() closes the session':
    'during init': (test) -> @connect ->
      @session.close()
      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        test.strictEqual res.statusCode, 400
        test.done()

    'after init': (test) -> @connect ->
      process.nextTick =>
        @session.close()

      @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
        test.strictEqual res.statusCode, 400
        test.done()

  # If you close immediately, the initial POST gets a 403 response (its probably an auth problem?)
  'An immediate session.close() results in the initial connection getting a 403 response': (test) ->
    @onSession = (@session) =>
      @session.close()

    @post '/channel/bind?VER=8&RID=1000&t=1', 'count=0', (res) ->
      buffer res, (data) ->
        test.strictEqual res.statusCode, 403
        test.done()

  # The session runs as a little state machine. It starts in the 'init' state, then moves to
  # 'ok' when the session is established. When the connection is closed, it moves to 'closed' state
  # and stays there forever.
  'The session emits a "state changed" event when you close it':
    'immediately': (test) -> @connect ->
      # Because we're calling close() immediately, the session should never make it to the 'ok' state
      # before moving to 'closed'.
      @session.on 'state changed', (nstate, ostate) =>
        test.strictEqual nstate, 'closed'
        test.strictEqual ostate, 'init'
        test.strictEqual @session.state, 'closed'
        test.done()

      @session.close()

    'after it has opened': (test) -> @connect ->
      # This time we'll let the state change to 'ok' before closing the connection.
      @session.on 'state changed', (nstate, ostate) =>
        if nstate is 'ok'
          @session.close()
        else
          test.strictEqual nstate, 'closed'
          test.strictEqual ostate, 'ok'
          test.strictEqual @session.state, 'closed'
          test.done()

  # close() also kills any active backchannel connection.
  'close kills the active backchannel': (test) -> @connect ->
    @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
      test.done()

    # Give it some time for the backchannel to establish itself
    soon => @session.close()
  
  # # node-browserchannel extensions
  #
  # browserchannel by default only supports sending string->string maps from the client to server. This
  # is really awful - I mean, maybe this is useful for some apps, but really you just want to send & receive
  # JSON.
  #
  # To make everything nicer, I have two changes to browserchannel:
  #
  # - If a map is `{JSON:"<JSON STRING>"}`, the server will automatically parse the JSON string and
  #   emit 'message', object. In this case, the server *also* emits the data as a map.
  # - The client can POST the forwardchannel data using a JSON blob. The message looks like this:
  #
  #     {ofs: 10, data:[null, {...}, 1000.4, 'hi', ....]}
  #
  #   In this case, the server *does not* emit a map, but merely emits the json object using emit 'message'.
  #
  #   To advertise this service, during the first test, the server sends X-Accept: application/json; ...
  'The server decodes JSON data in a map if it has a JSON key': (test) -> @connect ->
    data1 = [{}, {'x':null}, 'hi', '!@#$%^&*()-=', '\'"']
    data2 = "hello dear user"
    qs = querystring.stringify count: 2, ofs: 0, req0_JSON: (JSON.stringify data1), req1_JSON: (JSON.stringify data2)
    # I can guarantee qs is awful.
    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", qs, (res) =>

    @session.once 'message', (msg) =>
      test.deepEqual msg, data1

      @session.once 'message', (msg) ->
        test.deepEqual msg, data2
        test.done()

  # The server might be JSON decoding the data, but it still needs to emit it as a map.
  'The server emits JSON data in a map, as a map as well': (test) -> @connect ->
    data1 = [{}, {'x':null}, 'hi', '!@#$%^&*()-=', '\'"']
    data2 = "hello dear user"
    qs = querystring.stringify count: 2, ofs: 0, req0_JSON: (JSON.stringify data1), req1_JSON: (JSON.stringify data2)
    @post "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0", qs, (res) =>

    # I would prefer to have more tests mixing maps and JSON data. I'm better off testing that
    # thoroughly using a randomized tester.
    @session.once 'map', (map) =>
      test.deepEqual map, JSON: JSON.stringify data1

      @session.once 'map', (map) ->
        test.deepEqual map, JSON: JSON.stringify data2
        test.done()

  # The server also accepts raw JSON.
  'The server accepts JSON data': (test) -> @connect ->
    # The POST request has to specify Content-Type=application/json so we can't just use
    # the @post request. (Big tears!)
    options =
      method: 'POST'
      path: "/channel/bind?VER=8&RID=1001&SID=#{@session.id}&AID=0"
      host: 'localhost'
      port: @port
      headers:
        'Content-Type': 'application/json'

    req = http.request options, (res) ->
      readLengthPrefixedJSON res, (resData) ->
        # We won't get this response until all the messages have been processed.
        test.deepEqual resData, [0, 0, 0]
        test.deepEqual data, []
        test.expect 7

        res.on 'end', -> test.done()

    # This time I'm going to send the elements of the test object as separate messages.
    data = [{}, {'x':null}, 'hi', '!@#$%^&*()-=', '\'"']
    req.end (JSON.stringify {ofs:0, data})
  
    @session.on 'message', (msg) ->
      test.deepEqual msg, data.shift()

  # Hm- this test works, but the client code never recieves the null message. Eh.
  'You can send null': (test) -> @connect ->
    @session.send null

    req = @get "/channel/bind?VER=8&RID=rpc&SID=#{@session.id}&AID=0&TYPE=xmlhttp&CI=0", (res) =>
      readLengthPrefixedJSON res, (data) ->
        test.deepEqual data, [[1, null]]

        req.abort()
        test.done()

  'Sessions are cancelled when close() is called on the server': (test) -> @connect ->
    @session.on 'close', test.done
    @bc.close()

  #'print': (test) -> @connect -> console.warn @session; test.done()

  # I should also test that you can mix a bunch of JSON requests and map requests, out of order, and the
  # server sorts it all out.
