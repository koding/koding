# Wrapper for pushing events to Rollbar
if _rollbar? && KD.config.logToExternal then do ->
  KD.logToExternal = (args) ->
    _rollbar.push args

  # set user info in rollbar for people tracking
  KD.getSingleton('mainController').on "AccountChanged", (account) ->
    user = KD.whoami?().profile or KD.whoami()
    _rollbarParams.person =
      id: user.hash or user.nickname
      username: user.nickname
      name: user.firstName + " " + user.lastName
else
  KD.utils.stopRollbar()
  KD.logToExternal = (args) ->
