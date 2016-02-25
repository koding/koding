module.exports = hubspotTracker = (id, value) ->

  return  unless window._hsq
  return  unless id

  _hsq.push (t) -> t.trackEvent { id, value }
