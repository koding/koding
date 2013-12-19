# Wrapper for pushing events to Rollbar
if _rollbar? && KD.config.logToExternal then do ->
  KD.logToExternal = (args) ->
    _rollbar.push args  unless KD.isGuest()

  # log ping times so we know if failure was due to user's slow
  # internet or our internals timing out
  KD.logToExternalWithTime = (name, timeout)->
    KD.troubleshoot (times)->
      KD.logToExternal msg:"#{name} timed out in #{timeout}", pings:times

  # set user info in rollbar for people tracking
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    user = KD.whoami?().profile or KD.whoami()
    _rollbarParams.person =
      id       : user.hash or user.nickname
      name     : KD.utils.getFullnameFromAccount()
      username : user.nickname
else
  KD.utils.stopRollbar()
  KD.logToExternal         =->
  KD.logToExternalWithTime =->
