do->

  KD.kdMixpanel = new KDMixpanel
  KD.track = (rest...)->
    logToGoogle rest...
    KD.kdMixpanel.createEvent rest...

  logToGoogle = (rest...)->
    category = action = rest.first
    trackArray = ['_trackEvent', category, action]
    _gaq.push trackArray
