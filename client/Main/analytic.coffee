do->
  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    ga('send', 'pageview', argsForMixpanel.path)

    for own _ of argsForMixpanel.query
      KD.mixpanel "Visit page, success", argsForMixpanel
      break

    argsForMixpanel.username = KD.whoami()?.profile?.nickname
    KD.remote.api.JPageHit.create argsForMixpanel, ->
