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
  KD.mixpanel = (eventName, options)->
    mixpanel.track eventName, options

  KD.mixpanel.alias = (userId)->
    mixpanel.alias userId

  logToGoogle = (rest...)->
    category = action = rest.first
    trackArray = ['_trackEvent', category, action]
    _gaq.push trackArray
