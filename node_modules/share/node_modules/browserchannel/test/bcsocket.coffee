# # Tests for the bare BrowserChannel client.
#
# Run them by first launching
#
#     % coffee test/runserver.coffee
#
# ... Then browsing to localhost:4321 in your browser or running:
#
#     % nodeunit test/browserchannel.coffee
#
# from the command line. You should do both kinds of testing before pushing.
#
#
# These tests are pretty simple and primitive. The reality is, google's browserchannel
# client library is pretty bloody well tested. (I'm not interested in rewriting that test suite)
#
# However, its important to do some sanity checks on the exported browserchannel bits to
# make sure closure isn't doing anything wacky. Also this acts as a nice little integration
# test for the server, _and_ its useful to make sure that all the browsers node-browserchannel
# supports are behaving themselves.
#
# Oh yeah, and these tests will be run on the nodejs version of browserchannel, which has
# a lot of silly little parts.
#
# These tests will also be useful if the browserchannel protocol ever changes.
#
# Interestingly, most of the benefits of this test suite come from a single test (really, any
# test). If any test passes, they'll all probably pass.
#
#
# ## Known Issues
#
# There's three weird issues with this test suite:
#
# - Sometimes (maybe, 1 in 10) times the test is run from nodejs, it dies in a weird inconsistant
#   state.
# - Sometimes (about 1/4 times) the tests are run, the process doesn't exit for about 5 seconds after
#   the tests have finished. Presumably, there's a setTimeout() in the client somewhere which has
#   a race condition causing it to misbehave.
# - After a test run, 4 sessions are allowed to time out by the server. (Its odd because I'm calling
#   disconnect() in tearDown).


nodeunit = window?.nodeunit or require 'nodeunit'

if process.title is 'node'
  bc = require '..'
  # If coffeescript declares a variable called 'BCSocket' here, it will shadow the BCSocket variable
  # that is already defined in the browser. Doing it this way is pretty ugly, but it works and the ugliness
  # is constrained to a test.
  `BCSocket = bc.BCSocket`
  bc.setDefaultLocation 'http://localhost:4321'

module.exports = nodeunit.testCase
  tearDown: (callback) ->
    if @socket? and @socket.readyState isnt BCSocket.CLOSED
      @socket.onclose = -> callback()
      @socket.close()
      @socket = null
    else
      callback()

  # These match websocket codes
  'states and errors are mapped': (test) ->
    test.strictEqual BCSocket.CONNECTING, 0
    test.strictEqual BCSocket.OPEN, 1
    test.strictEqual BCSocket.CLOSING, 2
    test.strictEqual BCSocket.CLOSED, 3

    test.strictEqual BCSocket.prototype.CONNECTING, 0
    test.strictEqual BCSocket.prototype.OPEN, 1
    test.strictEqual BCSocket.prototype.CLOSING, 2
    test.strictEqual BCSocket.prototype.CLOSED, 3
    test.done()

  # Can we connect to the server?
  'connect': (test) ->
    @socket = new BCSocket '/notify'
    test.strictEqual @socket.readyState, BCSocket.CONNECTING

    @socket.onopen = =>
      test.strictEqual @socket.readyState, BCSocket.OPEN

    @socket.onerror = (reason) ->
      throw new Error reason

    @socket.onmessage = (message) ->
      test.deepEqual message, {appVersion: null}
      test.expect 3
      test.done()

  # The socket interface exposes browserchannel's app version thingy through
  # option arguments
  'connect sends app version': (test) ->
    @socket = new BCSocket '/notify', appVersion: 321

    @socket.onmessage = (message) ->
      test.deepEqual message, {appVersion:321}
      test.done()

  # BrowserChannel's native send method sends a string->string map.
  #
  # I want to test that I can send and recieve messages both before we've connected
  # (they should be sent as soon as the connection is established) and after the
  # connection has opened normally.
  'send maps': do ->
    # I'll throw some random unicode characters in here just to make sure...
    data = {'foo': 'bar', 'zot': '(◔ ◡ ◔)'}

    m = (callback) -> (test) ->
      @socket = new BCSocket '/echomap', appVersion: 321
      @socket.onmessage = (message) ->
        test.deepEqual message, data
        test.done()

      callback.apply this
    
    'immediately': m ->
      @socket.sendMap data

    'after we have connected': m ->
      @socket.onopen = =>
        @socket.sendMap data

  # I'll also test the normal send method. This is pretty much the same as above, whereby
  # I'll do the test two ways.
  'can send and receive JSON messages': do ->
    # Vim gets formatting errors with the cat face glyph here. Sad.
    data = [null, 1.5, "hi", {}, [1,2,3], '⚗☗⚑☯']

    m = (callback) -> (test) ->
      # Using the /echo server not /echomap
      @socket = new BCSocket '/echo', appVersion: 321
      @socket.onmessage = (message) ->
        test.deepEqual message, data
        test.done()

      callback.apply this
    
    'immediately': m ->
      # Calling send() instead of sendMap()
      @socket.send data

    'after we have connected': m ->
      @socket.onopen = =>
        @socket.send data

  # I have 2 disconnect servers which have slightly different timing regarding when they call close()
  # on the session. If close is called immediately, the initial bind request is rejected
  # with a 403 response, before the client connects.
  'disconnecting immediately results in REQUEST_FAILED and a 403': (test) ->
    @socket = new BCSocket '/dc1'

    @socket.onopen = -> throw new Error 'Socket should not have opened'

    @socket.onerror = (message, errCode) =>
      test.strictEqual message, 'Request failed'
      test.strictEqual errCode, 2
      test.done()

    @socket.onclose = ->
      throw new Error 'orly'

  'disconnecting momentarily allows the client to connect, then onclose() is called': (test) ->
    @socket = new BCSocket '/dc2', failFast: yes

    @socket.onerror = (message, errCode) =>
      # The error code varies here, depending on some timing parameters & browser.
      # I've seen NO_DATA, REQUEST_FAILED and UNKNOWN_SESSION_ID.
      test.strictEqual @socket.readyState, @socket.CLOSING
      test.ok message
      test.ok errCode

    @socket.onclose = (reason, pendingMaps, undeliveredMaps) =>
      # The error code varies here, depending on some timing parameters & browser.
      # These will probably be undefined, but == will catch that.
      test.strictEqual @socket.readyState, @socket.CLOSED
      test.equal pendingMaps, null
      test.equal undeliveredMaps, null
      test.expect 6
      test.done()

  'The client keeps reconnecting': do ->
    m = (base) -> (test) ->
      @socket = new BCSocket base, failFast: yes, reconnect: yes, reconnectTime: 300
      
      openCount = 0

      @socket.onopen = =>
        throw new Error 'Should not keep trying to open once the test is done' if openCount == 2

        test.strictEqual @socket.readyState, @socket.OPEN

      @socket.onclose = (reason, pendingMaps, undeliveredMaps) =>
        test.strictEqual @socket.readyState, @socket.CLOSED

        openCount++
        if openCount is 2
          # Tell the socket to stop trying to connect
          @socket.close()
          test.done()

    'When the connection fails': m('dc1')
#    'When the connection dies': m('dc3')

  'stop': do ->
    makeTest = (base) -> (test) ->
      # We don't need failFast for stop.
      @socket = new BCSocket base

      @socket.onerror = (message, errCode) =>
        test.strictEqual @socket.readyState, @socket.CLOSING
        test.strictEqual message, 'Stopped by server'
        test.strictEqual errCode, 7

      @socket.onclose = (reason, pendingMaps, undeliveredMaps) =>
        # These will probably be undefined, but == will catch that.
        test.strictEqual @socket.readyState, @socket.CLOSED
        test.equal pendingMaps, null
        test.equal undeliveredMaps, null
        test.strictEqual reason, 'Stopped by server'
        test.expect 7
        test.done()

    'on connect': makeTest 'stop1'
    'after connect': makeTest 'stop2'

  # This is a little stress test to make sure I haven't missed anything. Sending and recieving this much data
  # pushes the client to use multiple forward channel connections. It doesn't use multiple backchannel connections -
  # I should probably put some logic there whereby I close the backchannel after awhile.
  'Send & receive lots of data': (test) ->
    num = 5000

    @socket = new BCSocket '/echomap'

    received = 0
    @socket.onmessage = (message) ->
      received++

      test.done() if received == num

    process.nextTick =>
      @socket.sendMap {'aaaaaaaa': 'bbbbbbbb'} for [1..num]

