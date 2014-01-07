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
  KD.mixpanel = (args)-> mixpanel?.track args  if KD.config.logToExternal

  KD.mixpanel.alias = (args)-> KD.mixpanel args

  logToGoogle = (rest...)->
    category = action = rest.first
    trackArray = ['_trackEvent', category, action]
    _gaq.push trackArray

  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    unless argsForMixpanel.path in ['/']
      KD.mixpanel "Visit page, success", argsForMixpanel

    _gaq.push ['_trackPageview', argsForMixpanel.path]
