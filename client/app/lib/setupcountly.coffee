
bootCountly = (appKey) ->

  return if window.Countly

  c = {}
  c.q = []
  c.app_key = appKey
  c.url = '/countly'
  c.q.push ['track_sessions']
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
  remote = require 'app/remote'
  remote.api.JGroupData.fetchByKey 'countly', (err, data) ->
    return console.log 'err: countly wont be enabled', err if err
    return  unless data
    bootCountly data.appKey
