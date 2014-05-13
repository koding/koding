# Wrapper for pushing events to Rollbar
KD.logToExternal = (msg, args) ->
  console.warn "Rollbar is temporarily disabled"
  return

  # return  unless KD.config.logToExternal and _rollbar
  # return  if KD.isGuest()
  # return  unless KD.whoami()

  # {nickname} = KD.whoami().profile

  # if args? then args.user = nickname

  # Rollbar.info msg, args

# log ping times so we know if failure was due to user's slow
# internet or our internals timing out
KD.logToExternalWithTime = (name, options)->
  KD.troubleshoot (times)->
    KD.logToExternal "#{name} timed out", {
      options
      pings    : times
      protocol : KD.remote.mq.ws.protocol
    }
