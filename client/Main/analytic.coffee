do->
  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    _gaq.push ['_trackPageview', argsForMixpanel.path]

    for own _ of argsForMixpanel.query
      KD.mixpanel "Visit page, success", argsForMixpanel
      break

    KD.singletons.mainController.ready ->
      argsForMixpanel.username = KD.whoami()?.profile?.nickname
      KD.remote.api.JPageHit.create argsForMixpanel, ->
