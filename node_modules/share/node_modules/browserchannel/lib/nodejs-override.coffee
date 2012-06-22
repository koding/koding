# This fixes some bits and pieces so the browserchannel client works from nodejs.
#
# It is included after browserchannel when you closure compile node-browserchannel.js.
# This is closure compiled.

# For certain classes of error, browserchannel tries to get a test image from google.com 
# to check if the connection is still live.
#
# It also uses an image object with a particular URL when you call disconnect(), to tell
# the server that the connection has gone away.
#
# Its kinda clever, really.

goog.provide 'bc.node'

#goog.require 'bc'

request = require 'request'

Image = ->
  @__defineSetter__ 'src', (url) =>
    url = url.toString()
    if url.match /^\/\//
      url = 'http:' + url

    request url, (error, response, body) =>
      if error?
        @onerror?()
      else
        @onload?()
 
  this

# Create XHR objects using the nodejs xmlhttprequest library.
{XMLHttpRequest} = require '../XMLHttpRequest'

goog.require 'goog.net.XmlHttpFactory'

goog.net.BrowserChannel.prototype.createXhrIo = (hostPrefix) ->
  xhrio = new goog.net.XhrIo()
  xhrio.createXhr = -> new XMLHttpRequest()
  xhrio

# If you specify a relative test / bind path, browserchannel interprets it using window.location.
# I'll override that using a local window object with a fake location.
#
# Luckily, nodejs's url.parse module creates an object which is compatible with window.location.

window = {setTimeout, clearTimeout, setInterval, clearInterval}
window.location = null
window.navigator =
  userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.202 Safari/535.1"

###
  setTimeout: (f, t) ->
    console.log 'setTimeout'
    setTimeout (-> console.log(f.toString()); f()), t
  clearTimeout: clearTimeout
  setInterval: (f, t) ->
    console.log 'setTimeout'
    setInterval (-> console.log 'tick'; f()), t
  clearInterval: clearInterval
###

# This makes closure functions able to access setTimeout / setInterval. I don't know
# why they don't just access them directly, but thats closure for you.
goog.global = window

url = require 'url'

# Closure would scramble this name if we didn't specify it in quotes.
exports['setDefaultLocation'] = (loc) ->
  if typeof loc is 'string'
    loc = url.parse loc

  window.location = loc

