# Wrapper for pushing events to Mixpanel
if mixpanel? && KD.config.logToExternal then do ->

  # logs to Mixpanel X% of the time
  #   log errors, timeouts 100% of the time, success 20% of the time
  KD.logToMixpanel = (args, percent=100)->
    if KD.utils.runXpercent percent
      mixpanel.track args
      log "Log #{percent}% of time: #{args}"

  # send user info in Mixpanel for people tracking
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    return  if account instanceof KD.remote.api.JGuest

    user    = KD.whoami?().profile or KD.whoami()
    user_id = user.hash or user.nickname
    mixpanel.identify user_id
    mixpanel.people.set
      "$username": user.nickname
      "$name": user.firstName + " " + user.lastName

  status = KD.getSingleton "status"
  status.on "connected",    -> KD.logToMixpanel 5, "connected"
  status.on "disconnected", -> KD.logToMixpanel 100, "disconnected"
  status.on "reconnected",  -> KD.logToMixpanel 100, "reconnected"
else
  KD.utils.stopMixpanel()
  KD.logToMixpanel = (args, percent=100)->
