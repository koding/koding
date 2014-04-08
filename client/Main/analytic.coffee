do->
  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    _gaq.push ['_trackPageview', argsForMixpanel.path]

    if argsForMixpanel and (Object.keys(argsForMixpanel)).length is not 0
      KD.mixpanel "Visit page, success", argsForMixpanel

    argsForMixpanel.username = KD.whoami()?.profile?.nickname
    KD.remote.api.JPageHit.create argsForMixpanel, ->
