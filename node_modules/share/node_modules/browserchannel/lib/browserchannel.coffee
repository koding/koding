# These aren't required if we're pulling in the browserchannel code manually.

goog.provide 'bc'

goog.require 'goog.net.BrowserChannel'
goog.require 'goog.net.BrowserChannel.Handler'
goog.require 'goog.net.BrowserChannel.Error'
goog.require 'goog.net.BrowserChannel.State'

p = goog.net.BrowserChannel.prototype

p['getChannelDebug'] = p.getChannelDebug
p['setChannelDebug'] = p.setChannelDebug

p['connect'] = p.connect
p['disconnect'] = p.disconnect
p['getSessionId'] = p.getSessionId

p['getExtraHeaders'] = p.getExtraHeaders
p['setExtraHeaders'] = p.setExtraHeaders

p['getHandler'] = p.getHandler
p['setHandler'] = p.setHandler

p['getAllowHostPrefix'] = p.getAllowHostPrefix
p['setAllowHostPrefix'] = p.setAllowHostPrefix

p['getAllowChunkedMode'] = p.getAllowChunkedMode
p['setAllowChunkedMode'] = p.setAllowChunkedMode

p['isBuffered'] = p.isBuffered
p['sendMap'] = p.sendMap

p['setFailFast'] = p.setFailFast
p['isClosed'] = p.isClosed
p['getState'] = p.getState

p['getLastStatusCode'] = p.getLastStatusCode

# Not exposed:
# getForwardChannelMaxRetries
# getBackChannelMaxRetries
# getLastArrayId
# hasOutstandingRequests
# shouldUseSecondaryDomains
#
# I think most of these are only supposed to be used by channel request.


# We'll use closure's JSON serializer because IE doesn't come with a JSON serializer / parser.
goog.require 'goog.json'

# Add a little extra extension for node-browserchannel, for sending JSON data. The browserchannel server
# interprets {JSON:...} maps specially and decodes them automatically.
p['send'] = (message) ->
  @sendMap 'JSON': goog.json.serialize message

goog.net.BrowserChannel['Handler'] = goog.net.BrowserChannel.Handler

# I previously set up aliases for goog.net.BrowserChannel.[Error, State] but the
# closure seems to produce better code if you don't do that.
goog.net.BrowserChannel['Error'] =
  'OK':                 goog.net.BrowserChannel.Error.OK
  'REQUEST_FAILED':     goog.net.BrowserChannel.Error.REQUEST_FAILED
  'LOGGED_OUT':         goog.net.BrowserChannel.Error.LOGGED_OUT
  'NO_DATA':            goog.net.BrowserChannel.Error.NO_DATA
  'UNKNOWN_SESSION_ID': goog.net.BrowserChannel.Error.UNKNOWN_SESSION_ID
  'STOP':               goog.net.BrowserChannel.Error.STOP
  'NETWORK':            goog.net.BrowserChannel.Error.NETWORK
  'BLOCKED':            goog.net.BrowserChannel.Error.BLOCKED
  'BAD_DATA':           goog.net.BrowserChannel.Error.BAD_DATA
  'BAD_RESPONSE':       goog.net.BrowserChannel.Error.BAD_RESPONSE

goog.net.BrowserChannel['State'] =
  'CLOSED':  goog.net.BrowserChannel.State.CLOSED
  'INIT':    goog.net.BrowserChannel.State.INIT
  'OPENING': goog.net.BrowserChannel.State.OPENING
  'OPENED':  goog.net.BrowserChannel.State.OPENED

goog.exportSymbol 'goog.net.BrowserChannel', goog.net.BrowserChannel, exports ? window
