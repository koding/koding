whoami = require './whoami'

module.exports = hubspotTracker = (id, value) ->

  account = whoami()

  return  unless window._hsq
  return  unless id

  _hsq.push (t) -> t.identify { email : account.email }
  _hsq.push (t) -> t.trackEvent { id, value }
