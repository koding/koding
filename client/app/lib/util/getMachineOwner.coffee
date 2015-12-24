remote = require('app/remote').getInstance()


module.exports = (machine) ->

  switch machine.get 'provider'
    when 'koding','managed'
      return machine.get('credential')
    else # Use users array for other types of providers ~ GG
      jMachine = remote.revive machine.toJS()

      for user in jMachine.users when user.owner
        return user.username
