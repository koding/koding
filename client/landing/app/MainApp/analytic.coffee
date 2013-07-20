KD.track = (rest...)->
  logToGoogle rest...
  kdMixpanel = new KDMixpanel
  kdMixpanel.createEvent rest...

logToGoogle = (rest...)->
  category = action = rest.first
  trackArray = ['_trackEvent', category, action]
  _gaq.push trackArray
