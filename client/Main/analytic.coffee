do->
  KD.singleton('router').on "RouteInfoHandled", (argsForMixpanel)->
    KD.gaPageView argsForMixpanel.path

    for own _ of argsForMixpanel.query
      KD.mixpanel "Visit page, success", argsForMixpanel
      break

    KD.singletons.mainController.ready ->
      argsForMixpanel.username  = KD.whoami()?.profile?.nickname
      argsForMixpanel.userAgent = window.navigator.userAgent
      argsForMixpanel.protocol  = KD.remote.mq.ws.protocol

      if KD.config.logToInternal
        KD.remoteLog?.api.JPageHit.create argsForMixpanel, ->

do->
  lastGAMessage = null
  userIdle      = false
  threshold     = KD.config.troubleshoot.idleTime # 5 mins

  idleUserDetector = new IdleUserDetector {threshold}

  idleUserDetector.on "userIdle", -> userIdle = true
  idleUserDetector.on "userBack", -> gaHeartbeat()

  KD.gaPageView = (args...)->
    gaSend "pageview", args...

  gaHeartbeat =->
    KD.gaEvent "Heartbeat"

  KD.gaEvent = (args...)->
    gaSend "event", args...

  gaSend = (args...)->
    return  unless ga and KD.config.logToExternal

    lastGAMessage = new Date
    ga "send", args...

  # send a heartbeat to GA every five mins unless user is idle
  # or another event was sent to GA recently; this is required
  # to get an accurate count of current active users on GA.
  setInterval ->
    if ((new Date) - lastGAMessage) > threshold and !userIdle
      gaHeartbeat()
  , threshold
