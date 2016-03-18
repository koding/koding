# Wrapper for pushing events to Rollbar
module.exports = (msg, args) ->
  console.warn 'Rollbar is temporarily disabled'
  return

  # return  unless KD.config.logToExternal and _rollbar
  # return  if KD.isGuest()
  # return  unless KD.whoami()

  # {nickname} = KD.whoami().profile

  # if args? then args.user = nickname

  # Rollbar.info msg, args
