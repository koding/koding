remote = require 'app/remote'


module.exports = getMachineOwner = (_machine) ->

  switch _machine.get 'provider'
    when 'managed'
      return _machine.get 'credential'
    else # Use users array for other types of providers ~ GG
      machine = remote.revive _machine.toJS()
      for user in machine.users when user.owner
        return user.username
