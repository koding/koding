# # Tests for the bare BrowserChannel client.
#
# > The bare browserchannel client is no longer exposed by default. If you actually want to use this,
# > file a ticket or something.
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
  # I'd like to just say goog = bc.goog or something, but then coffeescript makes goog a variable,
  # which overrides goog defined in the window object in a browser.
  # Doing it this way makes goog a javascript global variable in nodejs, but that hardly matters.
  goog ?= bc.goog
  goog.setDefaultLocation 'http://localhost:4321'

makeTests = (configure) -> nodeunit.testCase
  setUp: (callback) ->
    # We need a session and a handler in every test.
    @session = new goog.net.BrowserChannel 123
    @handler = new goog.net.BrowserChannel.Handler()
    configure? @session, @handler
    #@session.setFailFast true
    @session.setHandler @handler
    callback()

  tearDown: (callback) ->
    if @session.getState() is goog.net.BrowserChannel.State.OPENED
      # Its important that we close the channel at this point because early versions of IE
      # can't handle having lots of concurrent connections to a server. We need to clean
      # up the old ones before making new ones.
      @handler.channelClosed = -> callback()
      @session.disconnect()
    else
      # If we're opening, calling disconnect() will stop trying to connect. However, it won't
      # call any callbacks. Skip on to the next test.
      @session.disconnect() if @session.getState() is goog.net.BrowserChannel.State.OPENING
      callback()

  # Can we connect to the server?
  'connect': (test) ->
    @handler.channelOpened = (session_) =>
      test.strictEqual session_, @session
      test.strictEqual @session.getState(), goog.net.BrowserChannel.State.OPENED

    @handler.channelHandleArray = (session_, message) ->
      test.deepEqual message, 123
      test.expect 4
      test.done()

    test.strictEqual @session.getState(), goog.net.BrowserChannel.State.INIT
    @session.connect "/notify/test", "/notify/bind"

  'states and errors are mapped': (test) ->
    # I won't test all of the state and error codes, but I'll test a few just to make sure they're
    # there. Knowing google, these won't change between browserchannel versions.
    test.strictEqual goog.net.BrowserChannel.State.CLOSED, 0
    test.strictEqual goog.net.BrowserChannel.State.OPENED, 3
    test.strictEqual goog.net.BrowserChannel.Error.OK, 0
    test.strictEqual goog.net.BrowserChannel.Error.UNKNOWN_SESSION_ID, 6
    test.done()

  # BrowserChannel's native send method sends a string->string map.
  'send maps': (test) ->
    # I'll throw some random unicode characters in here just to make sure...
    data = {'foo': 'bar', 'zot': '(◔ ◡ ◔)'}
    @handler.channelHandleArray = (session_, message) ->
      test.deepEqual message, data
      test.done()

    @session.connect "/echomap/test", "/echomap/bind"
    @session.sendMap data

  'can send and receive JSON messages': (test) ->
    # Wheee vim gets formatting errors with the cat face glyph here.
    data = [null, 1.5, "hi", {}, [1,2,3], '⚗☗⚑☯']
    @handler.channelHandleArray = (session_, message) ->
      test.deepEqual message, data
      test.done()

    @session.connect "/echo/test", "/echo/bind"
    # This is using the .send extension method, which JSON-encodes a message and sends it as {JSON:...}
    @session.send data

  # I have 2 disconnect servers which have slightly different timing regarding when they call close()
  # on the session. If close is called immediately, the initial bind request is rejected
  # with a 403 response, before the client connects.
  'disconnecting immediately results in REQUEST_FAILED and a 403': (test) ->
    @handler.channelOpened = (session_) ->
      throw new Error 'Channel should not have opened'

    # For some reason, sometimes nodeunit frieks the crap out here and (after the test has completed!)
    # throws a bunch of assertions, claiming that the session's last status code is -1, etc. I don't know
    # what *could* cause that sort of behaviour.
    @handler.channelError = (session, errCode) =>
      test.strictEqual errCode, goog.net.BrowserChannel.Error.REQUEST_FAILED
      test.strictEqual 403, @session.getLastStatusCode()
      test.done()

    # Interestingly, we don't have to set failFast for this to work.
    @session.connect "/dc1/test", "/dc1/bind"

  'disconnecting momentarily allows the client to connect, then channelClosed() is called': (test) ->
    @handler.channelError = (session, errCode) =>
      # The error code varies here, depending on some timing parameters & browser. I've seen NO_DATA, REQUEST_FAILED and
      # UNKNOWN_SESSION_ID.
      test.ok errCode

    @handler.channelClosed = (session_, pendingMaps, undeliveredMaps) ->
      # These will probably be undefined, but == will catch that.
      test.equal pendingMaps, null
      test.equal undeliveredMaps, null
      test.expect 3
      test.done()

    @session.setFailFast true
    @session.connect "/dc2/test", "/dc2/bind"
    
  'stop': do ->
    makeTest = (base) -> (test) ->
      @handler.channelError = (session, errCode) ->
        test.strictEqual errCode, goog.net.BrowserChannel.Error.STOP

      @handler.channelClosed = (session_, pendingMaps, undeliveredMaps) ->
        # These will probably be undefined, but == will catch that.
        test.equal pendingMaps, null
        test.equal undeliveredMaps, null
        test.expect 3
        test.done()
      
      # We don't need failFast for stop.
      @session.connect "/#{base}/test", "/#{base}/bind"

    'on connect': makeTest 'stop1'
    'after connect': makeTest 'stop2'

  # This is a little stress test to make sure I haven't missed anything. Sending and recieving this much data
  # pushes the client to use multiple forward channel connections. It doesn't use multiple backchannel connections -
  # I should probably put some logic there whereby I close the backchannel after awhile.
  'Send & receive lots of data': (test) ->
    num = 5000

    received = 0
    @handler.channelHandleArray = (session, message) ->
      received++

      test.done() if received == num

    @session.connect "/echomap/test", "/echomap/bind"

    process.nextTick =>
      @session.sendMap {'aaaaaaaa': 'bbbbbbbb'} for [1..num]

exports['normal'] = makeTests()
exports['chunk mode off'] = makeTests (session, handler) ->
  session.setAllowChunkedMode false

