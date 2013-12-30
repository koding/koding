# Wrapper for pushing events to Rollbar
KD.logToExternal = (args) ->
  if KD.config.logToExternal
    _rollbar?.push args  unless KD.isGuest()
  else
    log "Rolllbar disabled"

# log ping times so we know if failure was due to user's slow
# internet or our internals timing out
KD.logToExternalWithTime = (name, options)->
  KD.troubleshoot (times)->
    KD.logToExternal {
      options
      msg:"#{name} timed out"
      pings:times
    }

# set user info in rollbar for people tracking
KD.getSingleton('mainController').on "AccountChanged", (account) ->
  if KD.config.logToExternal
    user = KD.whoami?().profile or KD.whoami()
    _rollbarParams?.person =
      id       : user.hash or user.nickname
      name     : KD.utils.getFullnameFromAccount()
      username : user.nickname
