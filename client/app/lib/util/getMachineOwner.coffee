remote = require 'app/remote'


module.exports = getMachineOwner = (_machine) ->

  switch _machine.get 'provider'
    when 'managed'
      return _machine.get 'credential'
    else # Use users array for other types of providers ~ GG
      users = (_machine.get 'users').toJS()
      for user in users when user.owner
        return user.username
