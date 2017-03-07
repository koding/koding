remote = require 'app/remote'


module.exports = getMachineOwner = (machine) ->

  switch machine.get 'provider'
    when 'managed'
      return machine.get('credential')
    else # Use users array for other types of providers ~ GG
      jMachine = remote.revive machine.toJS()

      for user in jMachine.users when user.owner
        return user.username
