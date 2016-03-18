whoami = require './whoami'

module.exports = (flagToCheck, account = whoami()) ->
  if account.globalFlags
    if 'string' is typeof flagToCheck
      return flagToCheck in account.globalFlags
    else
      for flag in flagToCheck
        if flag in account.globalFlags
          return yes
  return no
