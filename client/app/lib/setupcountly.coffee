
bootCountly = (appKey) ->

  return if window.Countly

  c = {}
  c.q = []
  c.app_key = appKey
  c.url = '/countly'
  # track sessions automatically
  c.q.push ['track_sessions']
  #track sessions automatically
  c.q.push ['track_pageview']

  window.Countly = c

  cly = document.createElement 'script'
  cly.type = 'text/javascript'
  cly.async = false
  cly.src = '/countly/sdk/web/countly.min.js'
  cly.onload = -> window.Countly.init()
  s = document.getElementsByTagName('script')[0]
  s.parentNode.insertBefore cly, s


module.exports = ->
  getCurrentGroup = require 'app/util/getGroup'
  group = getCurrentGroup()
  return  unless group.countly?.appKey
  bootCountly group.countly?.appKey
