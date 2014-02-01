do->
  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    KD.mixpanel "Visit page, success", argsForMixpanel

    _gaq.push ['_trackPageview', argsForMixpanel?.path]
