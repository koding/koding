do->

  KD.kdMixpanel = new KDMixpanel
  KD.track = (rest...)->
    logToGoogle rest...
    KD.kdMixpanel.createEvent rest...

  # Access control wrapper around mixpanel object.
  #
  # eventName should be in form of '<verb> <noun>' with an
  # implicit 'User' in front.
  #
  # Ex: 'Followed user'
  KD.mixpanel = mixpanel.track

  KD.mixpanel.alias = mixpanel.alias

  logToGoogle = (rest...)->
    category = action = rest.first
    trackArray = ['_trackEvent', category, action]
    _gaq.push trackArray
