do->
  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    unless argsForMixpanel?.path in ['/', '/Activity', '/Terminal', '/Ace']
      KD.mixpanel "Visit page, success", argsForMixpanel

    _gaq.push ['_trackPageview', argsForMixpanel?.path]
